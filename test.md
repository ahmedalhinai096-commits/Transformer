عدّل دالة `exportExcel()` الحالية بحيث لا تصدّر CSV، بل تصدّر ملف Excel حقيقي بصيغة `.xlsx` باستخدام مكتبة SheetJS `xlsx`.

الهدف: يكون ملف التصدير مطابق تقريبًا للملف المرفوع `transformer_report.xlsx` من ناحية:

* تقسيم الأعمدة.
* دمج خلايا الهيدر.
* ألوان الهيدر.
* عرض الأعمدة.
* تجميد الصفوف والأعمدة.
* تنسيق الجداول والحدود.
* المعادلات الخاصة بالإجماليات و MAX و MIN و Load % و Action.

المطلوب بالتحديد:

1. استبدل إنشاء CSV بإنشاء Workbook و Worksheet:

   * استخدم `XLSX.utils.book_new()`
   * استخدم `XLSX.utils.aoa_to_sheet(rows)`
   * صدّر الملف باسم:
     `transformers_YYYYMMDD.xlsx`

2. اجعل الهيدر 3 صفوف مثل الملف المرفوع:

   * الأعمدة A:F تكون مدموجة عموديًا من الصف 1 إلى 3:

     * Area
     * H.T Feeder No.
     * Tx. No.
     * Tap No.
     * Capacity
     * Time
   * G:L عنوانها المدموج: `Voltage Value`
   * داخلها:

     * G:I = `Phase Voltage`
     * J:L = `Line Voltage`
     * الصف الثالث:

       * G = R/N
       * H = Y/N
       * I = B/N
       * J = R/B
       * K = Y/R
       * L = B/Y

3. الفيدرات:

   * من M إلى AR
   * كل Feeder يأخذ 4 أعمدة:

     * R
     * Y
     * B
     * N
   * اجعل الصف الأول مدموج لكل فيدر:

     * Feeder 1 على M:P
     * Feeder 2 على Q:T
     * Feeder 3 على U:X
     * Feeder 4 على Y:AB
     * Feeder 5 على AC:AF
     * Feeder 6 على AG:AJ
     * Feeder 7 على AK:AN
     * Feeder 8 على AO:AR
   * الصف الثاني والثالث للفيدرات يحتويان R/Y/B/N.

4. الأعمدة الأخيرة:

   * AS:AV مدموجة في الصف الأول بعنوان `Total Load`
   * تحتها R/Y/B/N
   * AW مدموج من AW1:AW3 بعنوان `MAX Value`
   * AX مدموج من AX1:AX3 بعنوان `MIN Value`
   * AY مدموج من AY1:AY3 بعنوان `Load %`
   * AZ مدموج من AZ1:AZ3 بعنوان `Action (Upgrade)`
   * BA مدموج من BA1:BA3 بعنوان `Action (Balance)`

5. لا تضف عمود `Reading Date` إذا لم يكن موجودًا في الملف المرفوع، لأن آخر عمود في القالب هو BA.

6. طبّق الدمج التالي في `ws['!merges']`:

   * A1:A3, B1:B3, C1:C3, D1:D3, E1:E3, F1:F3
   * G1:L1
   * G2:I2
   * J2:L2
   * M1:P1, Q1:T1, U1:X1, Y1:AB1, AC1:AF1, AG1:AJ1, AK1:AN1, AO1:AR1
   * AS1:AV1
   * AW1:AW3, AX1:AX3, AY1:AY3, AZ1:AZ3, BA1:BA3

7. طبّق عرض الأعمدة مثل القالب:

   * A = 14
   * B = 9
   * C = 8
   * D = 5
   * E = 9
   * F:L = 6
   * M:AR = 5
   * AS:AV = 6
   * AW:AX = 7
   * AY = 9
   * AZ:BA = 24

8. طبّق تجميد مثل الملف:

   * Freeze panes عند G4
   * يعني تثبيت أول 3 صفوف وأول 6 أعمدة.

9. طبّق الستايل:

   * كل الهيدر محاذاة وسط أفقي وعمودي.
   * `wrapText: true`
   * حدود رفيعة لكل الخلايا.
   * الصفوف 1 إلى 3 ارتفاعها 19.5.
   * صفوف البيانات ارتفاعها 15.75.
   * استخدم ألوان مشابهة:

     * الأعمدة الأساسية A:F لون أزرق فاتح `D9E1F2`
     * Voltage لون أزرق فاتح جدًا `EBF3FF`
     * Feeders ألوان الفازات:

       * R برتقالي `FF6600`
       * Y أصفر/ذهبي `FFC000`
       * B سماوي `66FFFF`
       * N رمادي فاتح `F2F2F2`
     * Total Load لون أخضر فاتح `E2EFDA`
     * Load % أصفر `FFFF00`
     * Actions لون برتقالي فاتح `FFF2CC`

10. في صفوف البيانات:

* ابدأ البيانات من الصف 4.
* احتفظ بنفس منطق قراءة البيانات من:

  * `records`
  * `loadings`
  * `volt`
  * `feeders`
* لا تغيّر أسماء الحقول الحالية.

11. اجعل خلايا الإجمالي والمعادلات كـ Excel formulas وليس أرقام محسوبة فقط:

* Total R في AS:
  `SUM(Mrow,Qrow,Urow,Yrow,ACrow,AGrow,AKrow,AOrow)`
* Total Y في AT:
  `SUM(Nrow,Rrow,Vrow,Zrow,ADrow,AHrow,ALrow,AProw)`
* Total B في AU:
  `SUM(Orow,Srow,Wrow,AArow,AErow,AIrow,AMrow,AQrow)`
* Total N في AV:
  `SUM(Prow,Trow,Xrow,ABrow,AFrow,AJrow,ANrow,ARrow)`
* MAX في AW:
  `MAX(ASrow:AUrow)`
* MIN في AX:
  `MIN(ASrow:AUrow)`
* Load % في AY:
  `(AWrow/(Erow/0.75))*100`
* Action Upgrade في AZ:
  `IF(AYrow>70,"Upgrade","OK no need to Upgrade")`
* Action Balance في BA:
  `IF(AWrow-AXrow<=10,"Ok no need to balance","need to balance")`

12. غيّر رسالة النجاح إلى:

* عربي: `📊 تم تصدير ملف Excel بنفس تنسيق التقرير`
* إنجليزي: `📊 Excel report exported with template styling`

أعطني الكود النهائي الكامل لدالة `exportExcel()` فقط، جاهز للنسخ والاستبدال، بدون شرح طويل.
