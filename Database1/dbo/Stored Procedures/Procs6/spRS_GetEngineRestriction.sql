/* This SP used by Report Server V2 */
CREATE PROCEDURE dbo.spRS_GetEngineRestriction
@ReportDefId int,
@EngineName varchar(50)
 AS
Declare @EngineRestriction varchar(255)
Declare @EngineExclusion varchar(255)
Declare @Yes int
Declare @No int
Select @Yes = 0, @No = 1
-- Every engine EXCEPT @EngineName can run @ReportDefId
exec spRS_GetReportParamValue 'EngineExclusion', @ReportDefId, @EngineExclusion output
-- Only @EngineName can run @ReportDefId
exec spRS_GetReportParamValue 'EngineRestriction', @ReportDefId, @EngineRestriction output
-----------------------------------------------------
-- Every Engine  E X E C P T  This Engine Is Allowed
-- If Exclusion Parameter Is Present Then
--   If The Excluded Name = Engine Name Then
--      Do Not Allow
-----------------------------------------------------
If @EngineExclusion Is Not Null
Begin
     If LTrim(RTrim(Upper(@EngineExclusion))) = LTrim(RTrim(Upper(@EngineName)))
     Begin
          print 'Engine ' + @EngineExclusion + ' will never be allowed to run this report'
          Return @No
     End
End
-----------------------------------------------------
-- Only  T H I S  Engine Is Allowed
-- If Restriction Parameter Is Present Then
--   If The Restricted Name <> Engine Name Then
--      Do Not Allow
-----------------------------------------------------
If @EngineRestriction Is Not Null
Begin
     If LTrim(RTrim(Upper(@EngineRestriction))) <> LTrim(RTrim(Upper(@EngineName)))
     Begin
          print 'Only engine ' + @EngineRestriction + ' can run this report'
          Return @No
     End
End
-----------------------------------------------------
-- No Reason Not To Assign
-----------------------------------------------------
print 'This engine can run this report'
Return @Yes
