import pypdf, sys
src = r"C:\Users\oobbee\Downloads\2026-实验1-数字系统设计基础实验（第2次课）.pdf"
dst = r"D:\FPGA_Lab\_docs\exp1_2026_class2_guide.txt"
r = pypdf.PdfReader(src)
out = []
for i, p in enumerate(r.pages, 1):
    out.append(f"===== Page {i}/{len(r.pages)} =====")
    t = p.extract_text() or ""
    out.append(t)
open(dst, "w", encoding="utf-8").write("\n".join(out))
print("pages:", len(r.pages), "->", dst)
