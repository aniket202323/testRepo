
CREATE Procedure [dbo].[spPO_ChangeCustomProperties]
(@customPropForWrite dbo.ProcessOrderCustomPropertyTableParam READONLY)
AS
    SET NOCOUNT ON


    IF EXISTS (Select 1 from @customPropForWrite cpw
               group by cpw.PropertyDefinitionId
               having count(*) > 1)
        BEGIN
            SELECT Error = 'ERROR: Duplicate PropertyDefinitionId not allowed', Code = 'InvalidData', ErrorType = 'DuplicatePropertyDefinitionId', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            RETURN
        END

DECLARE @ProcessOrderId int
select @ProcessOrderId = ProcessOrderId from @customPropForWrite

    IF (@ProcessOrderId is null)
        BEGIN
            SELECT Error = 'ERROR: Unable to update, process order id should be provided', Code = 'InvalidData', ErrorType = 'ProcessOrderIdMissing', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            RETURN
        end

CREATE TABLE #ProcessOrderCustomPropertyTemp_Available(Process_Order_Id bigint, Property_definition_id uniqueidentifier,Value NVARCHAR (max))
CREATE TABLE #ProcessOrderCustomPropertyTemp_Add(Process_Order_Id bigint, Property_definition_id uniqueidentifier,Value NVARCHAR (max))
CREATE TABLE #ProcessOrderCustomPropertyTemp_Delete(Property_definition_id uniqueidentifier)


--Populating temp table for available

INSERT INTO #ProcessOrderCustomPropertyTemp_Available
SELECT Process_Order_Id, Property_definition_id, Value
FROM process_order_custom_property_value
WHERE Process_Order_Id = @ProcessOrderId


    -- Populating temp table for add
INSERT INTO #ProcessOrderCustomPropertyTemp_Add
SELECT tpc.ProcessOrderId, tpc.PropertyDefinitionId, tpc.PropertyValue
FROM @customPropForWrite tpc
WHERE tpc.PropertyDefinitionId not in (Select Property_definition_id from #ProcessOrderCustomPropertyTemp_Available)

    -- Populating temp table for delete
INSERT INTO #ProcessOrderCustomPropertyTemp_Delete
SELECT #ProcessOrderCustomPropertyTemp_Available.Property_definition_id
FROM #ProcessOrderCustomPropertyTemp_Available
WHERE #ProcessOrderCustomPropertyTemp_Available.Property_definition_id not in (select PropertyDefinitionId from @customPropForWrite)


    --All the validations are done , so beginning a transaction so that we can rollback on each step in case if there is an error
    BEGIN TRANSACTION

    -- Updating
UPDATE pocpv
SET pocpv.Value = cp.PropertyValue
FROM dbo.process_order_custom_property_value pocpv
         INNER JOIN @customPropForWrite cp ON pocpv.Process_Order_Id = cp.ProcessOrderId AND  pocpv.Property_definition_id = cp.PropertyDefinitionId

    -- Adding

if exists(select 1 from #ProcessOrderCustomPropertyTemp_Add)
    begin
        insert into dbo.process_order_custom_property_value(Process_Order_Id, Property_definition_id, Value) select Process_Order_Id, Property_definition_id, Value   from #ProcessOrderCustomPropertyTemp_Add
    end




    --- Deleting, All delete logic is a bit different than one delete

DECLARE @AllDelete int = 0, @Rows int = 0;
Select @Rows = Count(*) from @customPropForWrite
Declare @PropertyDefId nvarchar(max) = Null
Select @PropertyDefId = PropertyDefinitionId from  @customPropForWrite
    If( @Rows = 1 AND @PropertyDefId is NULL)
        BEGIN
            Select @AllDelete = 1
        END

if(@AllDelete = 1)
    BEGIN
        DELETE FROM process_order_custom_property_value WHERE Process_Order_Id = @ProcessOrderId
    END
ELSE IF exists(select 1 from #ProcessOrderCustomPropertyTemp_Delete)
    BEGIN
        DELETE FROM process_order_custom_property_value WHERE Process_Order_Id = @ProcessOrderId And Property_definition_Id in (Select Property_Definition_Id from #ProcessOrderCustomPropertyTemp_Delete)
    end


-- If the sproc comes here then it executed successfully. Otherwise we would have throw the error
--IF we reach here no errors so far we can commit this transaction
    COMMIT TRANSACTION
