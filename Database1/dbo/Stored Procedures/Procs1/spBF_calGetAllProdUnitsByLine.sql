CREATE PROCEDURE dbo.spBF_calGetAllProdUnitsByLine
   @lineId INTEGER,
   @isLineId INTEGER
AS
BEGIN
 	 -- SET NOCOUNT ON added to prevent extra result sets from
 	 -- interfering with SELECT statements.
 	 SET NOCOUNT ON;
  SELECT pu.pu_id,pu.pu_desc + '[' + pl.PL_Desc+ ']' as pu_desc,pu.PU_Desc_Global,pu.pl_id, pu.Non_Productive_Reason_Tree as treeTypeId
    from Prod_Units pu join Prod_Lines_Base pl on pu.PL_Id = pl.PL_Id
     where pu.PL_Id > 0 and pl.Dept_Id > 0 and
           ( @isLineId = 0 or pu.pl_id = @lineId ) and ( @isLineId = 1 or pu.pu_id = @lineId )
    order by pu.pu_desc ;
END
