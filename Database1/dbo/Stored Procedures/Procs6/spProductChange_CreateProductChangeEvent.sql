
CREATE PROCEDURE dbo.spProductChange_CreateProductChangeEvent @PUId      INT,
                                                              @ProductId INT,
                                                              @TimeStamp DATETIME,
                                                              @UserId    INT,
                                                              @EventId   INT OUTPUT,
															  @TransactionType INT

 AS
BEGIN
    IF @PUId IS NULL
        BEGIN
            SELECT Code = 'InvalidData',
                   Error = 'Unit not found',
                   ErrorType = 'ParameterResourceNotFound',
                   PropertyName1 = 'PUId',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = @PUId,
                   PropertyValue2 = '',
                   PropertyValue3 = '',
                   PropertyValue4 = ''
            RETURN
        END
    IF NOT EXISTS(SELECT 1 FROM Prod_Units AS PU WHERE PU.PU_Id = @PUId)
        BEGIN
            SELECT Code = 'InvalidData',
                   Error = 'Invalid Production Unit',
                   ErrorType = 'InvalidParameterValue',
                   PropertyName1 = 'PUId',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = @PUId,
                   PropertyValue2 = '',
                   PropertyValue3 = '',
                   PropertyValue4 = ''
            RETURN
        END
    
    --As product change can be done for all types of sheets, We should chceck permissions for all sheets.
    DECLARE @SheetIds INTEGERTABLETYPE
    INSERT INTO @SheetIds
    SELECT Sheet_Id FROM Sheets WHERE Master_Unit = @PUId
                                      
     IF NOT EXISTS(SELECT 1 FROM(SELECT dbo.fnActivities_CheckSheetSecurityForActivities(Item, 208, 3, @PUId, @UserId) AS AddSecurity FROM @SheetIds) AS S WHERE S.AddSecurity = 1)
        BEGIN
            SELECT Code = 'InsufficientPermission',
                   Error = 'Insufficient permissions to change product',
                   ErrorType = 'Unauthorized',
                   PropertyName1 = 'Sheet',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = '',
                   PropertyValue2 = '',
                   PropertyValue3 = '',
                   PropertyValue4 = ''

            RETURN
        END                                     

    IF @ProductId IS NULL
        BEGIN
            SELECT Code = 'InvalidData',
                   Error = 'Product not found',
                   ErrorType = 'ParameterResourceNotFound',
                   PropertyName1 = 'ProductId',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = @ProductId,
                   PropertyValue2 = '',
                   PropertyValue3 = '',
                   PropertyValue4 = ''
            RETURN
        END
    IF NOT EXISTS(SELECT 1 FROM dbo.Products_Base AS PB WHERE PB.Prod_Id = @ProductId)
        BEGIN
            SELECT Code = 'InvalidData',
                   Error = 'Invalid Product',
                   ErrorType = 'InvalidParameterValue',
                   PropertyName1 = 'ProductId',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = @ProductId,
                   PropertyValue2 = '',
                   PropertyValue3 = '',
                   PropertyValue4 = ''
            RETURN
        END
    IF @Timestamp IS NULL
        BEGIN
            SELECT Code = 'InvalidData',
                   Error = 'Timestamp not found',
                   ErrorType = 'InvalidParameterValue',
                   PropertyName1 = 'Timestamp',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = '',
                   PropertyValue2 = '',
                   PropertyValue3 = '',
                   PropertyValue4 = ''
            RETURN
        END
    DECLARE @TimestampDB DATETIME= dbo.fnServer_CmnConvertToDBTime(@Timestamp, 'UTC')
   
    IF EXISTS(SELECT 1 FROM dbo.Production_Starts AS PS WHERE PS.PU_Id = @PUId
                                                              AND PS.Prod_Id = @ProductId
                                                              AND PS.Start_Time <= @TimestampDB
                                                              AND (PS.End_Time IS NULL
                                                                   OR PS.End_Time > @TimestampDB))
        BEGIN
            SELECT Code = 'EventRecordConflict',
                   Error = 'Invalid - The selected product is already running in the selected time',
                   ErrorType = 'ProductConflict',
                   PropertyName1 = 'ProductId',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = @ProductId,
                   PropertyValue2 = '',
                   PropertyValue3 = '',
                   PropertyValue4 = ''
            RETURN
        END

          IF @TransactionType = 1 AND EXISTS(SELECT 1 FROM dbo.Production_Starts AS PS WHERE PS.PU_Id = @PUId
                                                              --AND PS.Prod_Id = @ProductId
                                                              AND PS.Start_Time = @TimestampDB
                                                              AND (PS.End_Time IS NULL
                                                                   OR PS.End_Time > @TimestampDB))
        BEGIN
            SELECT Code = 'EventRecordConflict',
                   Error = 'Invalid - New product must be different from previous product',

                   ErrorType = 'ProductConflict',
                   PropertyName1 = 'ProductId',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = @ProductId,
                   PropertyValue2 = '',
                   PropertyValue3 = '',
                   PropertyValue4 = ''
            RETURN
        END

    DECLARE @CurrentEnd DATETIME, @ModifiedStart DATETIME, @ModifiedEnd DATETIME, @ProductCode Nvarchar(25)

    EXEC spServer_DBMgrUpdGrade2 @EventId OUTPUT, @PUId, @ProductId, NULL, @TimestampDB OUTPUT, 1010, @UserId, NULL, NULL, @CurrentEnd OUTPUT, @ProductCode OUTPUT, 2, @ModifiedStart OUTPUT, @ModifiedEnd OUTPUT

    SELECT @EventId AS                                                 EventId,
           @ProductId AS                                               ProductId,
           @ProductCode AS                                             ProductCode,
           dbo.fnServer_CmnConvertFromDbTime(@TimestampDB, 'UTC') AS   CurrentStart,
           dbo.fnServer_CmnConvertFromDbTime(@CurrentEnd, 'UTC') AS    CurrentEnd,
           dbo.fnServer_CmnConvertFromDbTime(@ModifiedStart, 'UTC') AS ModifiedStart,
           dbo.fnServer_CmnConvertFromDbTime(@ModifiedEnd, 'UTC') AS   ModifiedEnd
END


