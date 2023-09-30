

CREATE Procedure [dbo].[spWaste_getWasteEventConfigurations]
@UserId             int
AS
    /* Copyright (c) 2019 GE Digital. All rights reserved.
     *
     * The copyright to the computer software herein is the property of GE Digital.
     * The software may be used and/or copied only with the written permission of
     * GE Digital or in accordance with the terms and conditions stipulated in the
     * agreement/contract under which the software has been supplied.
     */


DECLARE @SecurityOptions Table (PU_Id int, AddComments Int, AssignReasons int, ChangeComments int,
                                CopyPasteReasons int, DeleteRecords int, InsertRecords int, ChangeTime int, ChangeFault int, ChangeLocation int,
                                FilterDisplay int, ChangeAmount int)

-- Getting PermissionInfo on all the available master units for the user
INSERT INTO @SecurityOptions select * from dbo.fnWaste_GetWastePermissions(@UserId, null)


-- Using the fetched permissions and Joining ProdEvents table to get configuration and permission for all the available units,
-- Slave units will have same permissions as master unit, but they might have different configurations [like action tree id and reason tree id]
select pub.PU_Id,pub.Master_Unit, pe.Name_Id as 'Cause_Tree_Id', pe.Action_Tree_Id, so.AddComments,
       so.AssignReasons, so.ChangeAmount, so.ChangeComments, so.ChangeFault, so.ChangeLocation, so.ChangeTime, so.CopyPasteReasons,
       so.DeleteRecords, so.FilterDisplay, so.InsertRecords
from  Prod_Units_Base pub
          JOIN @SecurityOptions as so on (so.PU_Id = COALESCE( pub.Master_Unit, pub.PU_Id))
          LEFT JOIN Prod_Events pe on (pe.PU_Id = pub.PU_Id and pe.Event_Type=3)

