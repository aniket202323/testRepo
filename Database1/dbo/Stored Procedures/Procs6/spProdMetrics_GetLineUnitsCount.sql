
CREATE PROCEDURE [dbo].[spProdMetrics_GetLineUnitsCount]
    @LineIds	nvarchar(max)

AS

	Create Table #Ids (Id Int)
	INSERT INTO #Ids (Id)  SELECT Id FROM dbo.fnCMN_IdListToTable('Line_list',@LineIds,',')
	
	IF ISNULL(@LineIds, '') <> '' /**  Check if LineIds is not null and not empty **/
		Begin
			SELECT COUNT(PU_Id) Unit_Count, PL_Id FROM Prod_Units WHERE PL_Id IN (select * from #Ids) AND Master_Unit IS NULL GROUP BY Pl_Id
		End
	ELSE
		Begin
			SELECT COUNT(PU_Id) Unit_Count, PL_Id FROM Prod_Units WHERE Master_Unit IS NULL GROUP BY Pl_Id			
		End
