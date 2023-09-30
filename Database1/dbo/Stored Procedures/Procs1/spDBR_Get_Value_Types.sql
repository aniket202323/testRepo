Create Procedure dbo.spDBR_Get_Value_Types
AS
 	 select Dashboard_Value_Code, 
 	 case when isnumeric(Dashboard_Value_Type_Desc) = 1 then (dbo.fnDBTranslate(N'0', Dashboard_Value_Type_Desc, Dashboard_Value_Type_Desc)) 
 	 else (Dashboard_Value_Type_Desc)
 	 end as Dashboard_Value_Type_Desc
 	 from Dashboard_Value_Types
