Create Procedure dbo.spEM_GetOEEReloadData
 AS
DECLARE  @TT Table(TIMECOLUMNS nvarchar(50))
Insert Into @TT  (TIMECOLUMNS) Values ('Min Time')
Insert Into @TT  (TIMECOLUMNS) Values ('Max Time')
select * from @TT
Select [Line] = Coalesce(pl.PL_Desc,''), 
 	    [Unit] = Coalesce(pu.PU_Desc,''),
 	    [Records] = Count(*),
 	    [Min Time] = Min(a.Start_Time),
 	    [Max Time] = Max(a.Start_Time)
 	      From OEEAggregation a
  Left Join Prod_Units pu on pu.PU_Id = a.PU_Id
  Left Join Prod_Lines pl on pl.Pl_Id = pu.Pl_Id
  WHERE Reprocess_Record != 0
  Group by PL_Desc,PU_Desc
  Order by PL_Desc,PU_Desc
