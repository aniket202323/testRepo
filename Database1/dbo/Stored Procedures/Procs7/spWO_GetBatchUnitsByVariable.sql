/*
set nocount on
exec spWO_GetBatchUnitsByVariable '698,378,5,10,7,8,40,41,50'
*/
CREATE PROCEDURE dbo.spWO_GetBatchUnitsByVariable
 	 @InputVariables varchar(7000)
AS
Declare @Variables table(Order_Id int, Var_Id int)
insert into @Variables select * from fnRS_MakeOrderedResultSet(@InputVariables)
select distinct puBatch.PU_ID, puBatch.PU_DESC
from @Variables v1
Join Variables v2 on v2.var_id = v1.var_id
Join Prod_Units pu on pu.pu_id = v2.pu_id
Join Prod_Units puBatch on pu.PL_Id = puBatch.PL_Id
Where puBatch.Extended_Info = 'BATCH:'
