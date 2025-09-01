********************************************************************************
* governance_fdi.do
* data panel untuk model: FDI inflows ~ Governance (instr: legal origin)
* User: Azlia Salsabila Risandri
********************************************************************************

clear all
set more off

* --------------- 1. Log file (opsional) ----------------
cap log close
log using "governance_fdi.log", replace text

* --------------- 2. Periksa & load data ----------------
import excel "C:\Users\HP\Downloads\[SMT 6 pt1]\FOR TUGAS AKHIR METOLIT\FIX_datapanel_tugasakhir_metolit(2).xlsx", sheet("Sheet1") firstrow clear

describe
summarize fdi ge psav rq gdp inflation legor id_country year

* --------------- 3. Buat var transformasi (IHS) -------------
* IHS (asinh) memungkinkan nilai negatif/0 dan mirip ln untuk nilai besar.
gen fdi_ihs = asinh(fdi)
gen gdp_ihs = asinh(gdp)
gen inflation_ihs = asinh(inflation)

* --------------- 4. Cek multikolinearitas awal antara GE/CC/RL -----
* Cek korelasi & VIF sebelum PCA
corr ge cc rl psav va rq
reg fdi_ihs ge cc rl psav va rq gdp_ihs inflation_ihs
estat vif

* --------------- 5. Buat indeks governance dengan PCA -----------
* Standarisasi dulu
egen z_ge = std(ge)
egen z_cc = std(cc)
egen z_va = std(va)
egen z_rl = std(rl)
egen z_psav = std(psav)
egen z_rq = std(rq)


* PCA: ambil komponen pertama
pca z_ge z_cc z_rl z_psav z_va z_rq, components(1)
predict governance, score

* Periksa kontribusi varians
sum governance

* --------------- 6. Buat dummy legal origin dari variabel legor -----------
* Legor berisi string seperti "UK","French","Socialist","German","Scandinavian"
* Normalisasi string
gen legor_s = lower(trim(legor))
gen legor_new = .

* Common law = 1, Civil law = 0
replace legor_new = 1 if legor_s == "uk"
replace legor_new = 0 if legor_s != "uk"

tab legor_new

* Pastikan tidak ada NA/missing unexpected
sum legor_new

* --------------- 7. Panel setup ----------------
xtset id_country year

* --------------- 8. OLS non robust ----------------
reg fdi_ihs governance gdp_ihs inflation_ihs
estat hettest
estat ovtest
predict resid, resid
sktest resid

* --------------- 9. OLS robust ----------------
reg fdi_ihs governance gdp_ihs inflation_ihs, robust
estimates store ols
estat vif

* --------------- 10. RE robust ----------------
xtreg fdi_ihs governance gdp_ihs inflation_ihs, re robust
estimates store re

* --------------- 11. FE robust ----------------
xtreg fdi_ihs governance gdp_ihs inflation_ihs, fe
estimates store fe

* --------------- 12. IV/2SLS ----------------
ivreg2 fdi_ihs (governance = legor_new) ///
       gdp_ihs inflation_ihs, first endog(governance)
estimates store iv

* --------------- 13. Perbandingan model ----------------
esttab ols re fe iv, ///
 stats(F r2 N, labels("F-Statistic" "R-squared" "Observasi")) ///
 mtitles("OLS" "Random Effects" "Fixed Effects" "IV/2SLS")
       star(* 0.1 ** 0.05 *** 0.01) 


