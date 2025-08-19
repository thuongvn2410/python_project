-- =========================
-- 0) Database ECTS (tạo Database)
-- =========================
--Run DB
docker run --name python_project -e POSTGRES_PASSWORD=python_project -p 5432:5432 -v pgdata:/home/thuongvn/postgresql/data -d postgres
--Tạo database
sudo docker exec -it python_project psql -U postgres
CREATE DATABASE "python_project";
quit

--Truy cập database để chạy câu lệnh
sudo docker exec -it python_project psql -U postgres -d python_project

-- =========================
-- 1) SUBJECTS (Môn học)
-- =========================
CREATE TABLE IF NOT EXISTS subjects (
  id   SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);

-- =========================
-- 2) QUESTIONS (Câu hỏi) - unit là TEXT tự do
-- =========================
CREATE TABLE IF NOT EXISTS questions (
  id           SERIAL PRIMARY KEY,
  subject_id   INTEGER NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  unit_text    TEXT,                      -- ví dụ: "Unit 1"
  question     TEXT NOT NULL,             -- nội dung câu hỏi
  mix_choices  INTEGER NOT NULL DEFAULT 1,-- 1=xáo đáp án; 0=giữ nguyên
  created_at   TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_questions_subject    ON questions(subject_id);
CREATE INDEX IF NOT EXISTS idx_questions_unit_text  ON questions(unit_text);

-- =========================
-- 3) CHOICES (Phương án)
-- =========================
CREATE TABLE IF NOT EXISTS choices (
  id          SERIAL PRIMARY KEY,
  question_id INTEGER NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  content     TEXT NOT NULL,
  is_correct  INTEGER NOT NULL DEFAULT 0, -- 1 = đáp án đúng
  position    INTEGER NOT NULL            -- thứ tự gốc
);
CREATE INDEX IF NOT EXISTS idx_choices_question ON choices(question_id);

-- TỐI ĐA 1 đáp án đúng/câu
CREATE UNIQUE INDEX uq_one_correct_per_question
ON choices(question_id)
WHERE is_correct = 1;

-- ÍT NHẤT 1 đáp án đúng/câu (không cho làm mất đáp án đúng cuối cùng)
CREATE OR REPLACE FUNCTION check_correct_answers()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'UPDATE' AND OLD.is_correct = 1 AND NEW.is_correct = 0) OR (TG_OP = 'DELETE' AND OLD.is_correct = 1) THEN
    IF NOT EXISTS (
      SELECT 1 FROM choices
      WHERE question_id = OLD.question_id
        AND id <> OLD.id
        AND is_correct = 1
    ) THEN
      RAISE EXCEPTION 'A question must have at least one correct answer';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_no_zero_correct_on_update
BEFORE UPDATE ON choices
FOR EACH ROW
EXECUTE FUNCTION check_correct_answers();

CREATE TRIGGER trg_no_zero_correct_on_delete
BEFORE DELETE ON choices
FOR EACH ROW
EXECUTE FUNCTION check_correct_answers();

-- =========================
-- 4) EXAMS (Khuôn đề)
-- =========================
CREATE TABLE IF NOT EXISTS exams (
  id               SERIAL PRIMARY KEY,
  subject_id       INTEGER NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  code             TEXT NOT NULL,           -- mã đợt/đề, ví dụ: ENG-MID-2025
  title            TEXT NOT NULL,
  duration_minutes INTEGER NOT NULL,
  num_questions    INTEGER NOT NULL,
  created_at       TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE(subject_id, code)
);
CREATE INDEX IF NOT EXISTS idx_exams_subject ON exams(subject_id);

-- =========================
-- 5) EXAM_VERSIONS (Mã đề)
-- =========================
CREATE TABLE IF NOT EXISTS exam_versions (
  id            SERIAL PRIMARY KEY,
  exam_id       INTEGER NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
  version_code  TEXT NOT NULL,              -- '101','102',...
  shuffle_seed  INTEGER NOT NULL,           -- seed để tái lập trộn
  created_at    TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE(exam_id, version_code)
);
CREATE INDEX IF NOT EXISTS idx_exam_versions_exam ON exam_versions(exam_id);

-- =========================
-- 6) EXAM_VERSION_QUESTIONS (Snapshot câu & thứ tự đáp án sau khi xáo)
-- =========================
CREATE TABLE IF NOT EXISTS exam_version_questions (
  id                  SERIAL PRIMARY KEY,
  exam_version_id     INTEGER NOT NULL REFERENCES exam_versions(id) ON DELETE CASCADE,
  question_id         INTEGER NOT NULL REFERENCES questions(id),
  question_position   INTEGER NOT NULL,     -- 1..N sau khi xáo câu
  choice_order_json   TEXT NOT NULL         -- JSON mảng choice.id theo thứ tự sau xáo
);
CREATE INDEX IF NOT EXISTS idx_evv_examversion ON exam_version_questions(exam_version_id);
CREATE INDEX IF NOT EXISTS idx_evv_question     ON exam_version_questions(question_id);





CREATE OR REPLACE FUNCTION trg_check_correct_choice()
RETURNS TRIGGER AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM choices
    WHERE question_id = NEW.question_id
      AND is_correct = 1
  ) THEN
    -- Báo lỗi bằng cách sử dụng RAISE EXCEPTION
    RAISE EXCEPTION 'Question must have a correct choice before being used in an exam';
  END IF;
  
  -- Trả về NEW để chèn bản ghi mới
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_exam_use_requires_correct
BEFORE INSERT ON exam_version_questions
FOR EACH ROW
EXECUTE FUNCTION trg_check_correct_choice();