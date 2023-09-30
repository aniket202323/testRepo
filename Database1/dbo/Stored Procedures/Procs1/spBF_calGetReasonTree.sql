CREATE PROCEDURE dbo.spBF_calGetReasonTree
        @treeType integer
AS
BEGIN
 	 -- SET NOCOUNT ON added to prevent extra result sets from
 	 -- interfering with SELECT statements.
 	 SET NOCOUNT ON;
select x.* from (
 select 0 as nodeId, null as Parent1, null as Parent2, null as Parent3, 
  'Available Reasons' as Reason_Name, 0 as Flags, 
   0 as Reason_ID, null as ParentReasonId, null as ParentNodeId, 
   0 as Reason_Level, 0 as Reason_Level_Update, @treeType as treeNameId
 UNION
  select * from dbo.cal_reasonTreeView
 ) x 
   where x.treeNameId = @treeType 
order by 1,2,3,4
END
