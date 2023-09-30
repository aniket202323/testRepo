
CREATE Procedure [dbo].[spPO_ChangeUdps]
(@customPropForWrite dbo.ProcessOrderUserDefinedPropertyTableParam READONLY)
AS
    SET NOCOUNT ON


    IF EXISTS (Select 1 from @customPropForWrite cpw
               group by cpw.PropertyDefinitionId
               having count(*) > 1)
        BEGIN
            SELECT Error = 'ERROR: Duplicate PropertyDefinitionId not allowed', Code = 'InvalidData', ErrorType = 'DuplicatePropertyDefinitionId', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            RETURN
        END


Declare @DatabaseTimeZone nvarchar(200)
select @DatabaseTimeZone = value from site_parameters where parm_id=192
DECLARE @ProcessOrderId int
DECLARE @TableId int
select @ProcessOrderId = ProcessOrderId from @customPropForWrite
select @TableId = TableId from @customPropForWrite

    IF (@ProcessOrderId is null)
        BEGIN
            SELECT Error = 'ERROR: Unable to update, process order id should be provided', Code = 'InvalidData', ErrorType = 'ProcessOrderIdMissing', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            RETURN
        end

    CREATE TABLE #ProcessOrderCustomPropertyTemp_Available(Process_Order_Id bigint, Property_definition_id bigint ,Value NVARCHAR (max), Table_id int)
    CREATE TABLE #ProcessOrderCustomPropertyTemp_Add(Process_Order_Id bigint, Property_definition_id bigint ,Value NVARCHAR (max), Table_id int)
    CREATE TABLE #ProcessOrderCustomPropertyTemp_Delete(Property_definition_id bigint)

    CREATE TABLE #CustomPropertyDateCorrection(ProcessOrderId bigint, FieldId bigint, PropertyValue nvarchar(max), TableId int, FieldType int)


    -- Doing date correction for field type = 12 [datetype]
    -- sproc receives datetime in UTC time zone, but it will be saved in database time zone

Insert Into #CustomPropertyDateCorrection (ProcessOrderId, FieldId, PropertyValue, TableId, FieldType ) Select ProcessOrderId, PropertyDefinitionId, PropertyValue, TableId, Null from @customPropForWrite

UPDATE #CustomPropertyDateCorrection set FieldType = ED_FieldTypes.ED_Field_Type_Id
From #CustomPropertyDateCorrection
         JOIN Table_Fields on #CustomPropertyDateCorrection.FieldId = Table_Fields.Table_Field_Id
         JOIN ED_FieldTypes on Table_Fields.ED_Field_Type_Id = ED_FieldTypes.ED_Field_Type_Id


UPDATE #CustomPropertyDateCorrection set PropertyValue = FORMAT(cast(PropertyValue as datetime) at time zone 'UTC' at time zone @DatabaseTimeZone, 'MMM dd yyyy hh:mm:sstt')
where FieldType = 12
DECLARE @customPropForWrite2 ProcessOrderUserDefinedPropertyTableParam
Insert into @customPropForWrite2(ProcessOrderId, PropertyDefinitionId, PropertyValue, TableId) select ProcessOrderId, FieldId, PropertyValue, TableId from #CustomPropertyDateCorrection






--Populating temp table for available. Create a table from the user input and select only those which are valid and available in the db

INSERT INTO #ProcessOrderCustomPropertyTemp_Available
SELECT KeyId, Table_Field_Id, Value, TableId
FROM Table_Fields_Values
WHERE KeyId = @ProcessOrderId and TableId = @TableId


    -- Populating temp table for add
INSERT INTO #ProcessOrderCustomPropertyTemp_Add
SELECT tpc.ProcessOrderId, tpc.PropertyDefinitionId, tpc.PropertyValue, tpc.TableId
FROM @customPropForWrite2 tpc
WHERE tpc.PropertyDefinitionId not in (Select Property_definition_id from #ProcessOrderCustomPropertyTemp_Available) --insert only if that property is not already attached. Need to test this. Currently this is not the requirement

-- Populating temp table for delete
INSERT INTO #ProcessOrderCustomPropertyTemp_Delete
SELECT #ProcessOrderCustomPropertyTemp_Available.Property_definition_id
FROM #ProcessOrderCustomPropertyTemp_Available
WHERE #ProcessOrderCustomPropertyTemp_Available.Property_definition_id not in (select PropertyDefinitionId from @customPropForWrite2 )  --select all those records which are there in the db but now not in the user input. Need to test this. Currently this is not the requirement


--All the validations are done , so beginning a transaction so that we can rollback on each step in case if there is an error
    BEGIN TRANSACTION

    -- Updating
UPDATE pocpv
SET pocpv.Value = cp.PropertyValue
FROM dbo.Table_Fields_Values pocpv
         INNER JOIN @customPropForWrite2 cp ON pocpv.KeyId = cp.ProcessOrderId AND  pocpv.Table_Field_Id = cp.PropertyDefinitionId AND pocpv.TableId = cp.TableId

    -- Adding

    if exists(select 1 from #ProcessOrderCustomPropertyTemp_Add)
        begin
            insert into dbo.Table_Fields_Values(KeyId, Table_Field_Id, Value, TableId) select Process_Order_Id, Property_definition_id, Value,  Table_id  from #ProcessOrderCustomPropertyTemp_Add
        end

    --- Deleting, All delete logic is a bit different than one delete

DECLARE @AllDelete int = 0, @Rows int = 0;
Select @Rows = Count(*) from @customPropForWrite2
Declare @PropertyDefId nvarchar(max) = Null
Select @PropertyDefId = PropertyDefinitionId from  @customPropForWrite2
    If( @Rows = 1 AND @PropertyDefId is NULL) --delete all properties
        BEGIN
            Select @AllDelete = 1
        END

    if(@AllDelete = 1)
        BEGIN
            DELETE FROM Table_Fields_Values WHERE Table_Field_Id = @ProcessOrderId AND TableId = @TableId
        END
    ELSE IF exists(select 1 from #ProcessOrderCustomPropertyTemp_Delete)
        BEGIN
            DELETE FROM Table_Fields_Values WHERE KeyId = @ProcessOrderId And TableId = @TableId And Table_Field_Id in (Select Property_Definition_Id from #ProcessOrderCustomPropertyTemp_Delete) --delete all which was already identified and put in temp table #ProcessOrderCustomPropertyTemp_Delete
        end


    -- If the sproc comes here then it executed successfully. Otherwise we would have throw the error
--IF we reach here no errors so far we can commit this transaction
    COMMIT TRANSACTION
