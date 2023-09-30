CREATE Procedure dbo.spWaste_GetWasteEventFault
    @PUId             int,
    @WasteEventFaultId int
AS
    /* Copyright (c) 2019 GE Digital. All rights reserved.
     *
     * The copyright to the computer software herein is the property of GE Digital.
     * The software may be used and/or copied only with the written permission of
     * GE Digital or in accordance with the terms and conditions stipulated in the
     * agreement/contract under which the software has been supplied.
     */

    --
    IF(@WasteEventFaultId is not null AND NOT EXISTS( SELECT 1 from Waste_Event_Fault where WEFault_Id = @WasteEventFaultId))
        BEGIN
            SELECT Error = 'Valid WasteEventFaultId required', Code = 'NotFound', ErrorType = 'WasteEventFaultIdNotFound', PropertyName1 = 'WasteEventFaultId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @WasteEventFaultId, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
        END
    IF(@PUId is not null AND NOT EXISTS( SELECT 1 from Prod_Units where PU_Id = @PUId))
        BEGIN
            SELECT Error = 'Valid PUId required', 'EWMS2110' as Code
        END
    IF(@WasteEventFaultId is not null )
        BEGIN
            SELECT  wef.WEFault_Id as WasteEventFaultId,wef.WEFault_Name as WasteEventFaultName, wef.Source_PU_Id as SourcePUId, /*= */
                    wef.WEFault_Value as WasteEventFaultValue,Reason_Level1,Reason_Level2,Reason_Level3,Reason_Level4,Event_Reason_Tree_Data_Id
            FROM Waste_Event_Fault wef
            WHERE   WEFault_Id  = @WasteEventFaultId
        END
    ELSE IF(@PUId is not null)
        SELECT  wef.WEFault_Id as WasteEventFaultId,wef.WEFault_Name as WasteEventFaultName, wef.Source_PU_Id as SourcePUId, /*= */
            wef.WEFault_Value as WasteEventFaultValue,Reason_Level1,Reason_Level2,Reason_Level3,Reason_Level4,Event_Reason_Tree_Data_Id
        FROM Waste_Event_Fault wef
        WHERE   PU_Id  = @PUId
    ELSE
        BEGIN
            SELECT  wef.WEFault_Id as WasteEventFaultId,wef.WEFault_Name as WasteEventFaultName, wef.Source_PU_Id as SourcePUId, /*= */
                    wef.WEFault_Value as WasteEventFaultValue,Reason_Level1,Reason_Level2,Reason_Level3,Reason_Level4,Event_Reason_Tree_Data_Id
            FROM Waste_Event_Fault wef
        END
