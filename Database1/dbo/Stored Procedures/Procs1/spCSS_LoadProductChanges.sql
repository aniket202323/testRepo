CREATE PROCEDURE dbo.spCSS_LoadProductChanges 
@UnitId int,
@StartTime datetime,
@EndTime datetime
AS
Select ps.*, p.Prod_Code, p.Prod_Desc, p.Comment_Id, p.External_Link
  From Production_Starts ps
  Join Products p on p.Prod_id = ps.Prod_Id
  Where ps.PU_Id = @UnitId and
            (
             (ps.Start_Time Between @StartTime and @EndTime) or 
             (ps.End_Time Between @StartTime and @EndTime) or 
             (
               (ps.Start_Time <= @StartTime) and 
               (
                 (ps.End_Time >= @EndTime) or (ps.End_Time Is Null )
               )
             )
            )
