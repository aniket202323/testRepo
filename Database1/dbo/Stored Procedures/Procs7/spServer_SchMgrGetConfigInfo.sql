CREATE PROCEDURE dbo.spServer_SchMgrGetConfigInfo     
AS
Select 
  a.Path_Id,
  a.PL_Id,
  a.Path_Desc,
  a.Path_Code,
  a.Is_Schedule_Controlled,
  a.Schedule_Control_Type,
  a.Is_Line_Production,
  b.PL_Desc,
  c.PP_Id,
  c.Forecast_Start_Date,
  c.Forecast_End_Date,
  c.Forecast_Quantity
From PrdExec_Paths a
Join Prod_Lines b on b.PL_Id = a.PL_Id
Left Outer Join Production_Plan c on (c.Path_Id = a.Path_Id) And (c.PP_Status_Id = 3)
Order By a.Path_Id
Select 
  a.Path_Id,
  a.Is_Production_Point,
  a.PU_Id,
  b.Production_Type,
  b.Production_Variable,
  b.PU_Desc
From PrdExec_Path_Units a
Join Prod_Units b on b.PU_Id = a.PU_Id
Order By a.Path_Id,a.PU_Id
