/*
@UnitList                - Comma separated list of production units
execute spBF_EquipmentSetUnitOrder '14,9,10,11,12,13',1
 select count(*),pl_id from prod_units group by pl_Id
 select pu_desc,pu_order,pu_id from prod_units where pl_id = 5 order by pu_order
*/
CREATE PROCEDURE dbo.spBF_EquipmentSetUnitOrder
  @UnitList                nvarchar(max),
  @UserId int
  AS
Declare @Units Table (NewOrder int Identity(1,1),UnitId int,PlId Int,OldOrder int)
DECLARE @PLId Int
If (@UnitList is Not Null)
 	 Set @UnitList = REPLACE(@UnitList, ' ', '')
if ((@UnitList is Not Null) and (LEN(@UnitList) = 0))
 	 Set @UnitList = Null
 insert into @Units (UnitId)
 	  	 select Id from [dbo].[fnCmn_IdListToTable]('Prod_Units',@UnitList,',') order by ItemOrder
if not exists(SELECT 1 FROM @Units)
BEGIN
 SELECT Error = 'Error: No Units Found'
 Return
END
update @Units set OldOrder = b.pu_order,PlId = b.PL_Id
FROM @Units a
Join Prod_Units_Base b on b.PU_Id = a.UnitId
/* all units must belong to same unit */
IF (SELECT Count(distinct PlId) from @Units) >1 
BEGIN
 	 SELECT Error = 'Error: Not all Units are on the same line'
 	 RETURN
END 
/* add rest of units */
SELECT @PLId = plid from @Units WHERE NewOrder = 1
INSERT INTO @Units(UnitId,PlId,OldOrder)
 	 SELECT PU_Id,PL_Id,pu_Order
 	  	 FROM Prod_Units_Base
 	  	 WHERE PL_Id = @PLId and PU_id not in (SELECT UnitId from @Units)
 	  	 ORDER BY PU_order,PU_Desc
Update Prod_Units_Base set PU_Order = neworder
FROM Prod_Units_Base a
Join @Units b on a.PU_Id = b.UnitId 
WHERE b.NewOrder <> a.PU_Order or a.PU_Order is null
SELECT 'Success'
