from docx import Document
import docx2txt
import os
from docx.table import Table
from docx.text.paragraph import Paragraph
import uuid
import shutil

def extract_images_from_docx(file_path, output_dir):
    """Trích xuất ảnh từ file .docx và lưu vào output_dir với tên duy nhất. Trả về danh sách tên ảnh."""
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    temp_dir = output_dir + "_tmp"
    if not os.path.exists(temp_dir):
        os.makedirs(temp_dir)
    docx2txt.process(file_path, temp_dir)
    image_names = []
    for fname in os.listdir(temp_dir):
        if fname.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp', '.gif')):
            unique_name = f"{uuid.uuid4().hex}{os.path.splitext(fname)[1]}"
            shutil.move(os.path.join(temp_dir, fname), os.path.join(output_dir, unique_name))
            image_names.append(unique_name)
    shutil.rmtree(temp_dir)
    return image_names

def read_docx_text_no_empty_with_images(file_path, image_names):
    """Đọc nội dung từ file .docx, đúng thứ tự văn bản và bảng, bỏ dòng rỗng, in kèm tên ảnh nếu có."""
    try:
        doc = Document(file_path)
        lines = []
        img_idx = 0
        for block in doc.element.body:
            if block.tag.endswith('tbl'):  # Nếu là bảng
                table = Table(block, doc)
                for row in table.rows:
                    row_text = []
                    for cell in row.cells:
                        cell_text = cell.text.strip()
                        # Nếu có ảnh, thêm tên ảnh vào cell (giả sử mỗi cell chứa tối đa 1 ảnh, lần lượt theo thứ tự trích xuất)
                        if img_idx < len(image_names) and cell_text:
                            cell_text += f" [Image: {image_names[img_idx]}]"
                            img_idx += 1
                        if cell_text:
                            row_text.append(cell_text)
                    if row_text:
                        lines.append(" | ".join(row_text))
            elif block.tag.endswith('p'):  # Nếu là đoạn văn
                para = Paragraph(block, doc)
                text = para.text.strip()
                if text:
                    lines.append(text)
        return "\n".join(lines)
    except Exception as e:
        import traceback
        print("Lỗi khi đọc file .docx:")
        traceback.print_exc()
        return None

if __name__ == "__main__":
    docx_file = "Template.docx"
    images_dir = "images_source"

    # Trích xuất ảnh và lấy danh sách tên ảnh mới
    image_names = extract_images_from_docx(docx_file, images_dir)

    # Đọc nội dung văn bản và bảng, in kèm tên ảnh nếu có
    text_content = read_docx_text_no_empty_with_images(docx_file, image_names)
    if text_content:
        print("--- Nội dung văn bản ---")
        print(text_content[:500] + "..." if len(text_content) > 500 else text_content)