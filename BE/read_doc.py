import textract

def read_doc_file(file_path):
    """
    Đọc nội dung từ một file .doc và trả về dưới dạng văn bản (text).
    """
    try:
        # textract.process sẽ trả về nội dung dưới dạng bytes
        content_bytes = textract.process('VM.docx')
        
        # Giải mã bytes thành chuỗi text
        content_text = content_bytes.decode('utf-8')
        
        return content_text
    except FileNotFoundError:
        return "Lỗi: File không tồn tại."
    except Exception as e:
        return f"Lỗi khi đọc file: {e}"

# Sử dụng hàm
doc_file = "ten_file_cua_ban.doc"
content = read_doc_file(doc_file)

if content:
    print(content)