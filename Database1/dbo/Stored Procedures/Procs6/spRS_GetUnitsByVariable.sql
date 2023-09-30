/*
set nocount on
exec spRS_GetUnitsByVariable '698,378,5,10,7,8,40,41,50'
*/
CREATE PROCEDURE dbo.spRS_GetUnitsByVariable
 	 @InputVariables varchar(7000)
AS
Declare @Variables table(Order_Id int, Var_Id int)
insert into @Variables select * from fnRS_MakeOrderedResultSet(@InputVariables)
select distinct pu.PU_ID, pu.PU_DESC
from @Variables v1
Join Variables v2 on v2.var_id = v1.var_id
Join Prod_Units pu on pu.pu_id = v2.pu_id
