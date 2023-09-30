CREATE Procedure dbo.spWaste_GetWasteMeasurements
@PUId             int,
@WasteMeasurementId int
AS
    /* Copyright (c) 2019 GE Digital. All rights reserved.
     *
     * The copyright to the computer software herein is the property of GE Digital.
     * The software may be used and/or copied only with the written permission of
     * GE Digital or in accordance with the terms and conditions stipulated in the
     * agreement/contract under which the software has been supplied.
     */

    --
    IF(@WasteMeasurementId is not null AND NOT EXISTS( SELECT 1 from Waste_Event_Meas where WEMT_Id = @WasteMeasurementId))
        BEGIN
            SELECT Error = 'ERROR: Valid WasteMeasurementId required', Code = 'NotFound', ErrorType = 'WasteMeasurementNotFound', PropertyName1 = 'WasteMeasurementId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @WasteMeasurementId, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
        END
    IF(@PUId is not null AND NOT EXISTS( SELECT 1 from Prod_Units where PU_Id = @PUId))
        BEGIN
            SELECT Error = 'ERROR: Valid PUId required', Code = 'NotFound', ErrorType = 'UnitNotFound', PropertyName1 = 'PUId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @PUId, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
        END
    IF(@WasteMeasurementId is not null )
        BEGIN
            SELECT  w.WEMT_Id,w.WEMT_Name,Conversion,Conversion_Spec,w.PU_ID
            FROM Waste_Event_Meas w
            WHERE w.WEMT_Id  = @WasteMeasurementId
        END
    ELSE IF(@PUId is not null)
        BEGIN
            SELECT  w.WEMT_Id,w.WEMT_Name,Conversion,Conversion_Spec,w.PU_ID
            FROM Waste_Event_Meas w
            WHERE w.PU_Id  = @PUId
        END
    ELSE
        BEGIN
            SELECT  w.WEMT_Id,w.WEMT_Name,Conversion,Conversion_Spec,w.PU_ID
            FROM Waste_Event_Meas w
        END
