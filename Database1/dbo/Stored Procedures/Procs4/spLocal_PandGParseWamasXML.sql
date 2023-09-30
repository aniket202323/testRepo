-- =============================================
-- Author:		Ethan
-- Create date: 7/18/2017
-- Description:	


-- =============================================
CREATE PROCEDURE [dbo].[spLocal_PandGParseWamasXML] 
	-- Add the parameters for the stored procedure here
	@WAMASXML xml = '',
	@WAMAS_XML_TYPE VARCHAR(100)
	
AS
BEGIN
	BEGIN TRY
		SELECT @WAMASXML as PassedInXML
		IF @WAMAS_XML_TYPE like 'Incoming Open request'
		BEGIN
			
			select 
			header.info.value('(/requestId)[1]','varchar(max)') AS RequestID,
			header.info.value('(/requestTime)[1]', 'datetime') AS RequestTime,
			header.info.value('(/deliveryLocation/locationId)[1]', 'varchar(max)') AS locationID,
			header.info.value('(/deliveryLocation/lineId)[1]', 'varchar(max)') AS LineID,
			header.info.value('(/materialGcas)[1]','varchar(max)') AS Gcas,
			header.info.value('(/requestQuantity/value)[1]','varchar(max)') AS Value,
			header.info.value('(/requestQuantity/UOM)[1]','varchar(max)') AS UOM
			from @WAMASXML.nodes('.') as header(info)
		END
		ELSE IF @WAMAS_XML_TYPE like 'Cancel Open request'
		BEGIN
			
			select 
			header.info.value('(/requestId)[1]','varchar(max)') AS RequestID,
			header.info.value('(/requestTime)[1]', 'datetime') AS RequestTime,
			header.info.value('(/cancelTime)[1]', 'datetime') AS CancelTime,
			header.info.value('(/deliveryLocation/locationId)[1]', 'varchar(max)') AS LocationID,
			header.info.value('(/deliveryLocation/lineId)[1]', 'varchar(max)') AS LineID,
			header.info.value('(/requestMaterialGcas/primaryGcas)[1]','varchar(max)') AS PrimaryGcas,
			header.info.value('(/requestMaterialGcas/alternateGcas)[1]','varchar(max)') AS AlternateGcas,
			header.info.value('(/requestQuantity/value)[1]','varchar(max)') AS RequestQuantity_Value,
			header.info.value('(/requestQuantity/UOM)[1]','varchar(max)') AS RequestQuantity_UOM,
			header.info.value('(/statusEvents/Status)[1]','varchar(max)') AS Status,
			header.info.value('(/statusEvents/StatusBegin)[1]','datetime') AS StatusBegin,
			header.info.value('(/ULID)[1]','varchar(max)') AS ULID,
			header.info.value('(/pickedQuantity/value)[1]','varchar(max)') AS PickedQuantity_Value,
			header.info.value('(/pickedQuantity/UOM)[1]','varchar(max)') AS PickedQuantity_UOM,
			header.info.value('(/pickedMaterialGcas)[1]','varchar(max)') AS PickedMaterialGcas,
			header.info.value('(/estimatedDeliveryTime)[1]','datetime') AS EstimatedDeliveryTime,
			header.info.value('(/lastUpdateTime)[1]','datetime') AS LastUpdateTime
			from @WAMASXML.nodes('.') as header(info)
		END
		ELSE IF @WAMAS_XML_TYPE like 'Update Open request'
		BEGIN
			
			select 
			header.info.value('(/requestId)[1]','varchar(max)') AS RequestID,
			header.info.value('(/requestTime)[1]', 'datetime') AS RequestTime,
			header.info.value('(/cancelTime)[1]', 'datetime') AS CancelTime,
			header.info.value('(/deliveryLocation/locationId)[1]', 'varchar(max)') AS LocationID,
			header.info.value('(/deliveryLocation/lineId)[1]', 'varchar(max)') AS LineID,
			header.info.value('(/requestMaterialGcas/primaryGcas)[1]','varchar(max)') AS PrimaryGcas,
			header.info.value('(/requestMaterialGcas/alternateGcas)[1]','varchar(max)') AS AlternateGcas,
			header.info.value('(/requestQuantity/value)[1]','varchar(max)') AS RequestQuantity_Value,
			header.info.value('(/requestQuantity/UOM)[1]','varchar(max)') AS RequestQuantity_UOM,
			header.info.value('(/statusEvents/Status)[1]','varchar(max)') AS Status,
			header.info.value('(/statusEvents/StatusBegin)[1]','datetime') AS StatusBegin,
			header.info.value('(/ULID)[1]','varchar(max)') AS ULID,
			header.info.value('(/pickedQuantity/value)[1]','varchar(max)') AS PickedQuantity_Value,
			header.info.value('(/pickedQuantity/UOM)[1]','varchar(max)') AS PickedQuantity_UOM,
			header.info.value('(/pickedMaterialGcas)[1]','varchar(max)') AS PickedMaterialGcas,
			header.info.value('(/vendorLot)[1]','varchar(max)') AS VendorLot,
			header.info.value('(/estimatedDeliveryTime)[1]','datetime') AS EstimatedDeliveryTime,
			header.info.value('(/lastUpdateTime)[1]','datetime') AS LastUpdateTime
			from @WAMASXML.nodes('.') as header(info)
		END
		ELSE IF @WAMAS_XML_TYPE = 'Line Delivery'
		BEGIN
			
			select 
			header.info.value('(/requestId)[1]','varchar(max)') AS RequestID,
			header.info.value('(/requestTime)[1]', 'datetime') AS RequestTime,
			header.info.value('(/deliveryLocation/locationId)[1]', 'varchar(max)') AS LocationID,
			header.info.value('(/deliveryLocation/lineId)[1]', 'varchar(max)') AS LineID,
			header.info.value('(/requestMaterialGcas/primaryGcas)[1]','varchar(max)') AS PrimaryGcas,
			header.info.value('(/requestMaterialGcas/alternateGcas)[1]','varchar(max)') AS AlternateGcas,
			header.info.value('(/requestQuantity/value)[1]','varchar(max)') AS RequestQuantity_Value,
			header.info.value('(/requestQuantity/UOM)[1]','varchar(max)') AS RequestQuantity_UOM,
			header.info.value('(/statusEvents/Status)[1]','varchar(max)') AS Status,
			header.info.value('(/statusEvents/StatusBegin)[1]','datetime') AS StatusBegin,
			header.info.value('(/ULID)[1]','varchar(max)') AS ULID,
			header.info.value('(/pickedQuantity/value)[1]','varchar(max)') AS PickedQuantity_Value,
			header.info.value('(/pickedQuantity/UOM)[1]','varchar(max)') AS PickedQuantity_UOM,
			header.info.value('(/pickedMaterialGcas)[1]','varchar(max)') AS PickedMaterialGcas,
			header.info.value('(/vendorLot)[1]','varchar(max)') AS VendorLot,
			header.info.value('(/estimatedDeliveryTime)[1]','datetime') AS EstimatedDeliveryTime,
			header.info.value('(/deliveredQuantity/value)[1]','varchar(max)') AS DeliveredQuantity_Value,
			header.info.value('(/deliveredQuantity/UOM)[1]','varchar(max)') AS DeliveredQuantity_UOM,
			header.info.value('(/deliveryTime)[1]','datetime') AS DeliveryTime
			from @WAMASXML.nodes('.') as header(info)
		END
		ELSE IF @WAMAS_XML_TYPE = 'Weighted Return'
		BEGIN
			
			select 
			header.info.value('(/requestId)[1]','varchar(max)') AS RequestID,
			header.info.value('(/ULID)[1]','varchar(max)') AS ULID,
			header.info.value('(/Location)[1]','varchar(max)') AS Location,
			header.info.value('(/materialGcas)[1]','varchar(max)') AS MaterialGcas,
			header.info.value('(/vendorLot)[1]','varchar(max)') AS VendorLot,
			header.info.value('(/returnedTime)[1]','datetime') AS ReturnedTime,
			header.info.value('(/returnedQuantity/value)[1]','varchar(max)') AS ReturnedQuantity_Value,
			header.info.value('(/returnedQuantity/UOM)[1]','varchar(max)') AS ReturnedQuantity_UOM
			from @WAMASXML.nodes('.') as header(info)
		END
	END TRY
	BEGIN CATCH

	END CATCH
END
