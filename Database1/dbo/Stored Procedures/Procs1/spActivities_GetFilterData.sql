
CREATE PROCEDURE [dbo].[spActivities_GetFilterData]
@EquipmentList NVARCHAR(max) = NULL --  Optional Filter List of Equipments from my machines

 AS

DECLARE @Ids Table (Id Int)
INSERT INTO @Ids (Id)  SELECT Id FROM dbo.fnCMN_IdListToTable('Prod_Units',@EquipmentList,',')

BEGIN
    SELECT Activity_Type_Id AS Event_Type_Id,
            Activity_Desc AS    Event_Type_Desc FROM Activity_Types order by Event_Type_Desc
END

BEGIN
    SELECT DISTINCT
            a.PU_Id AS            Unit_Id,
            c.PU_Desc AS          Unit_Desc,
            a.Activity_Type_Id AS Event_Type_Id,
            b.Activity_Desc AS    Event_Type_Desc
            FROM dbo.Activities AS a
                JOIN dbo.Activity_Types AS b ON a.Activity_Type_Id = b.Activity_Type_Id
                JOIN Prod_Units_Base AS c ON a.PU_Id = c.PU_Id
            WHERE a.PU_Id IN(SELECT Id FROM @Ids) order by c.PU_Desc
END
