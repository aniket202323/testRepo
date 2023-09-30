CREATE PROCEDURE dbo.spSupport_SheetVarMismatch 
AS 
select sv.var_id,v.Var_Desc,et.ET_Desc as 'Variable Event Type',s.Sheet_Id,s.Sheet_Desc,st.Sheet_Type_Desc 
from sheet_variables sv
join variables v on sv.var_id = v.var_id
join sheets s on sv.sheet_id = s.sheet_id
join Sheet_Type st on s.Sheet_Type = st.Sheet_Type_Id
join Event_Types et on v.Event_Type = et.et_id where
(s.Sheet_Type = 1 and v.Event_Type <> 0) or -- non-Time-based Variables on Time-based sheets
(s.Sheet_Type = 2 and v.Event_Type <> 1) or -- non-Production Event-based variables on Production Event-based sheets
(s.Sheet_Type = 16 and v.Event_Type <> 5) or -- non-Product-Time-based variables on Product-Time sheets
(s.Sheet_Type = 19 and v.Event_Type <> 17) or -- non-Genealogy variables on AutoLog Genealogy sheets
(s.Sheet_Type = 20 and v.Event_Type <> 2) or -- non-Downtime variables on AutoLog Downtime sheets
(s.Sheet_Type = 21 and v.Event_Type <> 19) or -- non-Process Order variables on AutoLog Process Order sheets
(s.Sheet_Type = 22 and v.Event_Type <> 28) or -- non-Process Order/Time variables on AutoLog Process Order/Time sheets
(s.Sheet_Type = 23 and v.Event_Type <> 4) or -- non-Product Change variables on Product Change sheets
(s.Sheet_Type = 24 and v.Event_Type <> 22) or -- non-Uptime variables on AutoLog Uptime sheets
(s.Sheet_Type = 25 and v.Event_Type <> 14) or -- non-UDE variables on UDE sheets
(s.Sheet_Type = 26 and v.Event_Type <> 3)-- non-Waste variables on AutoLog Waste sheets
order by s.Sheet_Desc,v.Var_Desc
