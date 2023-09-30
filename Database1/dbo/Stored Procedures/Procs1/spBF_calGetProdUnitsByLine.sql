CREATE PROCEDURE dbo.spBF_calGetProdUnitsByLine
   @lineId INTEGER,
   @isLineId INTEGER
AS
BEGIN
 	 -- SET NOCOUNT ON added to prevent extra result sets from
 	 -- interfering with SELECT statements.
 	 SET NOCOUNT ON;
  SELECT pu.pu_id,pu_desc = pu.pu_desc + '['+ pl.PL_Desc+ ']' ,pu.PU_Desc_Global,pu.pl_id, pu.Non_Productive_Reason_Tree as treeTypeId
    from Prod_Units pu 
 	 join Prod_Lines_Base pl on pu.PL_Id = pl.PL_Id
     where pu.Non_Productive_Category = 7 and pu.PL_Id > 0 and pl.Dept_Id > 0 and
           ( @isLineId = 0 or pu.pl_id = @lineId ) and ( @isLineId = 1 or pu.pu_id = @lineId )
    order by pu.pu_desc ;
END
