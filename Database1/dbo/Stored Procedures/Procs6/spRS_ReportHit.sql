/* This SP Used by Report Server V2 */
CREATE PROCEDURE dbo.spRS_ReportHit
@Report_Id int,
@User_Id int
 AS
Insert Into Report_Hits(
  Report_Id,
  User_Id,
  HitTime)
Values(
  @Report_Id,
  @User_Id,
  GetDate())
