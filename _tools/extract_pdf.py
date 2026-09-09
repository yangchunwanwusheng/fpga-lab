import fitz
import sys

src = r"C:\Users\oobbee\Downloads\2026-实验1-数字系统设计基础实验（第1次课）.pdf"
out = r"D:\FPGA_Lab\_docs\exp1_2026_class1_guide.txt"

doc = fitz.open(src)
lines = []
for i, page in enumerate(doc, 1):
    lines.append(f"===== Page {i}/{len(doc)} =====")
    lines.append(page.get_text("text"))
with open(out, "w", encoding="utf-8") as f:
    f.write("\n".join(lines))
print("pages:", len(doc))
print("chars:", sum(len(x) for x in lines))
