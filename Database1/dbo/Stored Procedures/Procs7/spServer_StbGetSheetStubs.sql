CREATE PROCEDURE dbo.spServer_StbGetSheetStubs
@GetNoTimeIntervalSheets int = 0 
 AS
declare @SheetVars table (Sheet_Id int, Var_Id int)
insert into @SheetVars (Sheet_Id, Var_Id)
select Sheet_Id, Var_Id
  From Sheet_Variables sv
  where Var_Order = (Select min(Var_Order) From Sheet_Variables 	 where Var_Id is not null and Sheet_Id = sv.Sheet_Id Group by Sheet_Id)
  Order By Sheet_Id
if (@GetNoTimeIntervalSheets = 1)
  Select s.Sheet_Id,s.Interval,s.Offset,dbo.fnServer_GetTimeZone(case when v.PU_Id is null then s.Master_Unit else v.PU_Id end)
    From Sheets s
 	  	 left outer join @SheetVars sv on sv.Sheet_Id = s.Sheet_Id
 	  	 left outer join Variables_Base v on v.Var_Id = sv.Var_Id
    Where (s.Event_Type = 0) And ((s.Interval = 0) or (s.Interval Is Null)) and s.Sheet_Type = 1
    Order by s.Sheet_Desc
else
  Select s.Sheet_Id,s.Interval,s.Offset,dbo.fnServer_GetTimeZone(case when v.PU_Id is null then s.Master_Unit else v.PU_Id end)
    From Sheets s
 	  	 left outer join @SheetVars sv on sv.Sheet_Id = s.Sheet_Id
 	  	 left outer join Variables_Base v on v.Var_Id = sv.Var_Id
    Where (s.Event_Type = 0) And (s.Interval >= 1) And (s.Interval Is Not Null)
    Order by s.Sheet_Desc
