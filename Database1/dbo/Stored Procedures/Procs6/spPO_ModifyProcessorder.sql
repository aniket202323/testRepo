
CREATE PROCEDURE [dbo].[spPO_ModifyProcessorder]
    @PP_Id int,
    @TransType int,
    @Path_Id int,
    @Comment_Id int,
    @Prod_Id int,
    @PP_Status_Id int,
    @PP_Type_Id int,
    @User_Id int,
    @Control_Type tinyint,
    @PlannedStartTime datetime,
    @PlannedEndTime datetime,
    @Forecast_Quantity float,
    @Production_Rate float,
    @Block_Number nvarchar(50),
    @Process_Order nvarchar(50),
    @BOM_Formulation_Id bigint = NULL,
    @User_General_1 	 nvarchar(255) = NULL,
    @User_General_2 	 nvarchar(255) = NULL,
    @User_General_3 	 nvarchar(255) = NULL,
    @Extended_Info 	 nvarchar(255) = NULL,
    @TransitionDirection int,
    @IsNormalUpdate bit = NULL,
    @Source_PP_ID_INPUT int,
    @PO_ID_ADDED BIGINT OUTPUT
    -- IsNormalUpdate is set to one when there's update on PO other than status, reOrdering or binding/unbinding. This update can be along with status change, reOrdering and Binding/Unbinding
    /*
    Possible values of transition direction = +1, -1
    +1 for move forward one step
    -1 for move back one step
    */
AS

    /*
    Transaction type 1 for insert records
    2 for update records [ with name or date times or quantity], Including Status change and sequence change
    3 for delete
    Note: in update, or insert if comment Id is there add it to the PP table
    We are not checking security here, so it should be verified from the Core
    */

    -- Transaction Numbers used by core sproc: spServer_DBMgrUpdProdPlan
    -- 00 - Coalesce
    -- 01 - Comment Update
    -- 02 - No Coalesce
    -- 03 - Call FROM Model 804
    -- 91 - Return To Parent Process Order
    -- 92 - Create Child Process Order Based On Start Time (@Misc1=Parent_PP_Setup_Id)
    -- 93 - Create Child Process Order Before Process Order (@Misc1=Parent_PP_Setup_Id)
    -- 94 - Create Child Process Order After Process Order (@Misc1=Parent_PP_Setup_Id)
    -- 95 - Re Work Process Order
    -- 96 - Bind/UnBind Process Order
    -- 97 - Process Order Status Transition
    -- 98 - Move Process Order Back
    -- 99 - Move Process Order Forward
    -- 1000 Update Comment


    /*
     All the operations involving <> operator has a Coalesce statement with them with -100 as alternative to null because
     <> is not null safe
     */


DECLARE @OldPath_Id INT, @OldStatusId INT, @OldPPID INT, @OldComment_Id INT, @OldPPTypeId INT, @CommentId_Final INT, @EntryOn_Old datetime, @ImpliedSequence_Old int, @Old_Process_Order nvarchar(100), @OldProdId int;
select @Old_Process_Order = Process_Order,@OldPath_Id = pp.Path_Id,@OldProdId = pp.Prod_Id, @OldStatusId = pp.PP_Status_Id, @OldPPID = pp.PP_Id, @OldComment_Id = pp.Comment_Id, @OldPPTypeId = pp.PP_Type_Id, @ImpliedSequence_Old = pp.Implied_Sequence, @EntryOn_Old = pp.Entry_On  from Production_Plan pp where PP_Id = @PP_Id;
    IF(@Comment_Id = 0)
        BEGIN
            select @Comment_Id = null;
        end
SELECT @CommentId_Final = coalesce(@Comment_Id, @OldComment_Id)

DECLARE	@return_value int, @ImpliedSequence int, @EntryOn datetime, @TransNum int, @SourcePPId int, @ParentPPId int, @AdjustedQuantity int, @TransactionTime datetime,
@statusTransPerm int;

DECLARE @InsertIntoPendingResultSet int = 1; -- Asking core sproc to push associated messages

---------------------------------------------------------------------------------------
------------------Validations for add and update --------------------------------------
---------------------------------------------------------------------------------------
    IF (@TransType = 1 OR @TransType = 2 )
        BEGIN

            if (@PlannedStartTime is  null)
                BEGIN
                    SELECT Error = 'ERROR: Planned Start Time cannot be blank', Code = 'InvalidData',  ErrorType = 'StartTimeNotProvided', PropertyName1 = 'PlannedStartTime', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                END

            -- Correct the startTime and EndTime:
            Declare @DatabaseTimeZone nvarchar(200)
            select @DatabaseTimeZone = value from site_parameters where parm_id=192

            SELECT @PlannedStartTime = @PlannedStartTime at time zone 'UTC' at time zone @DatabaseTimeZone  --dbo.fnServer_CmnConvertToDbTime(@PlannedStartTime,'UTC')
            -- trimming milliseconds from planned start time
            SELECT @PlannedStartTime  =  Dateadd(ms,-datepart(ms,@PlannedStartTime),@PlannedStartTime);

            IF(@PlannedEndTime is not NULL)
                BEGIN
                    SELECT @PlannedEndTime = @PlannedEndTime at time zone 'UTC' at time zone @DatabaseTimeZone  --dbo.fnServer_CmnConvertToDbTime(@PlannedEndTime,'UTC')
                    -- trimming milliseconds from planned start time
                    SELECT @PlannedEndTime  =  Dateadd(ms,-datepart(ms,@PlannedEndTime),@PlannedEndTime);

                end

            if (@PlannedStartTime is not null) and (@PlannedEndTime is not null) and (@PlannedStartTime >= @PlannedEndTime)
                BEGIN
                    SELECT Error = 'ERROR: Planned Start Time must be before Planned End Time', Code = 'InvalidData',  ErrorType = 'StartTimeNotBeforeEndTime', PropertyName1 = 'PlannedStartTime', PropertyName2 = 'PlannedEndTime', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @PlannedStartTime, PropertyValue2 = @PlannedEndTime, PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                END

            IF(@Process_Order is NULL OR @Process_Order = '')
                BEGIN
                    SELECT Error = 'ERROR: ProcessOrder is required field', Code = 'InvalidData',  ErrorType = 'EmptyPO', PropertyName1 = 'ProcessOrderName', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                END

            IF NOT EXISTS (Select 1 from Control_Type where Control_Type_Id = @Control_Type)
                BEGIN
                    SELECT Error = 'ERROR: Invalid Control Type', Code = 'InvalidData', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'ControlTypeId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Control_Type, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                END
            IF (@PP_Type_Id IS NULL OR NOT EXISTS(SELECT 1 FROM Production_Plan_Types WHERE PP_Type_Id = @PP_Type_Id))
                BEGIN
                    SELECT Error = 'ERROR: Order Type not found', Code = 'InvalidData', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'OrderTypeId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                END


            /*
            IF (@TransType = 2 AND @OldPath_Id is null)
                BEGIN
                    SELECT Error = 'ERROR: Unbounded PO Update not supported for now', Code = 'InvalidData', ErrorType = 'NonEditableField', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                end

             */


            /* check if the Path_Id is valid */
            IF (@Path_Id is NOT NULL AND NOT EXISTS( select 1 from Prdexec_Paths  where Path_Id = @Path_Id))
                BEGIN
                    SELECT Error = 'ERROR: Invalid Path_Id', Code = 'InvalidData', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'Path_Id', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Path_Id, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                END
            IF ( @Prod_Id IS NULL OR NOT EXISTS( select 1 from Products_Base where Prod_Id = @Prod_Id) )
                BEGIN
                    SELECT Error = 'ERROR: Invalid ProdId', Code = 'InvalidData', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'ProductId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                END

            IF @PP_Status_Id IS NULL OR NOT EXISTS (SELECT 1 from Production_Plan_Statuses where PP_Status_Id = @PP_Status_Id)
                BEGIN
                    SELECT Error = 'ERROR: Status not found', Code = 'InvalidData', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'OrderStatusId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @PP_Status_Id, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                END





            /* Now check if the productId can be used with this Path
               Do this check only if @Path_Id is not null
               */
            IF (@Path_Id is not NULL AND NOT EXISTS( select 1 from PrdExec_Path_Products  where PrdExec_Path_Products.Path_Id = @Path_Id AND PrdExec_Path_Products.Prod_Id = @Prod_Id))
                BEGIN
                    SELECT Error = 'ERROR: Product cannot be selected for the given path', Code = 'InvalidData', ErrorType = 'InvalidProdSelection', PropertyName1 = 'ProdId', PropertyName2 = 'Path_Id', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Prod_Id, PropertyValue2 = @Path_Id, PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                END

            /*
            Compatibility will not be forced from, because in few cases of [erp import] customer is not going to put the associated products
            --Now check the compatibility of BOM formulationId with productId
            IF(@BOM_Formulation_Id is not null)
                IF NOT EXISTS(select 1 from Bill_Of_Material_Product BOMP where BOMP.Prod_Id = @Prod_Id AND BOMP.BOM_Formulation_Id = @BOM_Formulation_Id)
                    BEGIN
                        SELECT Error = 'ERROR: BOM Formulation cannot be selected for the given prod', Code = 'InvalidData', ErrorType = 'InvalidBOMformulationSelection', PropertyName1 = 'BOM_Formulation_Id', PropertyName2 = 'Prod_Id', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @BOM_Formulation_Id, PropertyValue2 = @Prod_Id, PropertyValue3 = '', PropertyValue4 = ''
                        RETURN
                    END
             */
        END


    ---------------------------------------------------------------------------------------
------------------------Validations for update and delete --------------------------------------
    ---------------------------------------------------------------------------------------
    IF (@TransType = 2 OR @TransType = 3)
        BEGIN
            /*
             If status of process order is complete, do not allow delete
             */
            IF (@OldPPID is null)
                BEGIN
                    SELECT Error = 'ERROR: Process Order not found', Code = 'ResourceNotFound', ErrorType = 'ProcessOrderNotFound', PropertyName1 = 'PP_Id', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @PP_Id, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                END

            /*
            As per PAWAN's decision we will be allowing delete now. Keeping it comment here as decisions might change
            IF(@OldStatusId = 4 AND @TransType = 3)
                BEGIN
                    SELECT Error = 'ERROR: Delete Not Allowed on completed process orders', Code = 'InvalidData', ErrorType = 'DeleteNotAllowed', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                END

             */


        END


    ---------------------------------------------------------------------------------------
------------------------Validations for update --------------------------------------
    ---------------------------------------------------------------------------------------


    IF (@TransType = 2)
        BEGIN

            IF (Coalesce(@PP_Type_Id, -100) <> Coalesce(@OldPPTypeId, -100))
                BEGIN
                    SELECT Error = 'ERROR: OrderType cannot be changed', Code = 'InvalidData', ErrorType = 'NonEditableField', PropertyName1 = 'PP_Type_Id', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @PP_Type_Id, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                end


            /* For renaming a PO, Expensive check. Running only when required, This won't be checked in case of reordering or status change*/
            IF(@Old_Process_Order <> @Process_Order)
                BEGIN
                    IF EXISTS(SELECT 1 FROM Production_Plan WHERE Path_Id = @Path_Id   AND Process_Order = @Process_Order AND PP_Id <> @PP_Id)
                        OR EXISTS (SELECT 1 FROM Production_Plan WHERE Path_Id IS NULL   AND Process_Order = @Process_Order AND PP_Id <> @PP_Id AND @Path_Id IS NULL)
                        BEGIN
                            SELECT Error = 'ERROR: Process Order Name not Unique for the given path, Unable to Rename', Code = 'POConflict', ErrorType = 'PONameAlreadyUsed', PropertyName1 = 'Process_Order', PropertyName2 = 'Path_Id', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Process_Order, PropertyValue2 = @Path_Id, PropertyValue3 = '', PropertyValue4 = ''
                            RETURN
                        END
                END

            /*
                  If path is changed from a value to some other non null value, then it is not supported. path should be first set to null
                  then to other path, [unbinding/binding PO]
                  */
            IF (Coalesce(@Path_Id, -100) <> Coalesce(@OldPath_Id, -100) AND @Path_Id is not null AND @OldPath_Id is not null)
                BEGIN
                    SELECT Error = 'ERROR: Path cannot be changed', Code = 'InvalidData', ErrorType = 'NonEditableField', PropertyName1 = 'Path_Id', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @OldPath_Id, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                END

            /*
             Only name change is allowed for complete, planning, overproduced...... process orders
             For underproduced, only bom change is allowed
             */

            if(Coalesce(@Path_Id, -100) <> Coalesce(@OldPath_Id, -100))
                BEGIN

                    if(@PP_Status_Id = 3)
                        BEGIN
                            -- Unbinding/Binding not allowed for active POs
                            SELECT Error = 'ERROR: Unbinding or Binding PO not allowed for Active PO', Code = 'InvalidData', ErrorType = 'InvalidUnbinding', PropertyName1 = 'Path_Id', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @OldPath_Id, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                            RETURN
                        end

                    -- check for unbinding
                    if( @Path_Id is null AND @OldPath_Id is not null)
                        BEGIN
                            if(@PP_Status_Id = 2)
                                BEGIN
                                    --  if there's already a next unbounded order in table then we won't allow this unbinding
                                    DECLARE @OrdersNumExisting_1 INT = 0
                                    select @OrdersNumExisting_1 = count(*) from Production_Plan where Path_Id is NULL AND PP_Status_Id = @OldStatusId
                                    if(@OrdersNumExisting_1 > 0)
                                        BEGIN
                                            SELECT Error = 'ERROR: Maximum number of Process orders configured for the path with given status has reached', Code = 'POConflict', ErrorType = 'InvalidUnbinding', PropertyName1 = 'PP_Status_Id', PropertyName2 = 'PathId', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @PP_Status_Id, PropertyValue2 = @Path_Id, PropertyValue3 = '', PropertyValue4 = ''
                                            RETURN
                                        end
                                end

                            -- Check if PO name is already with the unbounded path
                                IF EXISTS(SELECT 1 FROM Production_Plan WHERE Path_Id = @Path_Id   AND Process_Order = @Process_Order AND PP_Id <> @PP_Id)
                                    OR EXISTS (SELECT 1 FROM Production_Plan WHERE Path_Id IS NULL   AND Process_Order = @Process_Order AND PP_Id <> @PP_Id AND @Path_Id IS NULL)
                                BEGIN
                                    SELECT Error = 'ERROR: Unbound Process Order already exist with this name', Code = 'POConflict', ErrorType = 'PONameAlreadyUsed', PropertyName1 = 'Process_Order', PropertyName2 = 'Path_Id', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Process_Order, PropertyValue2 = @Path_Id, PropertyValue3 = '', PropertyValue4 = ''
                                    RETURN
                                END
                        end

                    -- check for binding
                    if( @Path_Id is not null AND @OldPath_Id is null)
                        BEGIN
                            DECLARE @OrdersNumAllowed_Binding INT = null
                            select @OrdersNumAllowed_Binding = How_Many from PrdExec_Path_Status_Detail where Path_Id = @Path_Id AND PP_Status_Id = @PP_Status_Id
                            -- check if @Path_Id will take @PP_Status_Id
                            IF (@OrdersNumAllowed_Binding is not null)
                                BEGIN
                                    DECLARE @OrdersNumExisting_Binding INT = 0
                                    select @OrdersNumExisting_Binding = count(*) from Production_Plan where Path_Id = @Path_Id AND PP_Status_Id = @PP_Status_Id
                                    If (@OrdersNumExisting_Binding >= @OrdersNumAllowed_Binding)
                                        BEGIN
                                            SELECT Error = 'ERROR: Maximum number of Process orders configured for the path with given status has reached', Code = 'POConflict', ErrorType = 'InvalidBinding', PropertyName1 = 'PP_Status_Id', PropertyName2 = 'PathId', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @PP_Status_Id, PropertyValue2 = @Path_Id, PropertyValue3 = '', PropertyValue4 = ''
                                            RETURN
                                        end
                                end

                            -- check for the product in this binding
                            if NOT EXISTS(select 1 from PrdExec_Path_Products
                                          where PrdExec_Path_Products.Path_Id = @Path_Id AND PrdExec_Path_Products.Prod_Id = @Prod_Id)
                                BEGIN
                                    SELECT Error = 'ERROR: Process Order cannot be binded to provided path', Code = 'POConflict', ErrorType = 'InvalidBinding', PropertyName1 = 'Path_Id', PropertyName2 = 'Prod_Id', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Path_Id, PropertyValue2 = @Prod_Id, PropertyValue3 = '', PropertyValue4 = ''
                                    RETURN
                                end

                            -- Check if PO name is already with the path we are binding this PO to
                            IF EXISTS(SELECT 1 FROM Production_Plan WHERE Path_Id = @Path_Id   AND Process_Order = @Process_Order AND PP_Id <> @PP_Id)
                                OR EXISTS (SELECT 1 FROM Production_Plan WHERE Path_Id IS NULL   AND Process_Order = @Process_Order AND PP_Id <> @PP_Id AND @Path_Id IS NULL)                                BEGIN
                                    SELECT Error = 'ERROR: Process Order Name not Unique for the given path', Code = 'POConflict', ErrorType = 'PONameAlreadyUsed', PropertyName1 = 'Process_Order', PropertyName2 = 'Path_Id', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Process_Order, PropertyValue2 = @Path_Id, PropertyValue3 = '', PropertyValue4 = ''
                                    RETURN
                                END

                            -- TODO check for the binding of Active POs if the path will take this active PO, there is a defect in
                            -- Thick client as well
                        end

                    -- for binding unbind check feasibility based on binding and unbinding

                end


            /*
             For Status change
             */
            IF (Coalesce(@OldStatusId, -100) <> Coalesce(@PP_Status_Id, -100))
                BEGIN
                    /*On a path only one process order can be set to next*/
                    /*
                     Code review:
                     There is the property for number of POs on a path in status.
                     Path configurations , Schedule - HOW many
                     */
                    -- @OrdersNumAllowed -- Number of process orders allowed for requested PO status on pathId
                    DECLARE @OrdersNumAllowed_StatusChange INT = null
                    select @OrdersNumAllowed_StatusChange = How_Many from PrdExec_Path_Status_Detail where Path_Id = @Path_Id AND PP_Status_Id = @PP_Status_Id
                    if(@Path_Id is null AND (@PP_Status_Id = 2 OR @PP_Status_Id = 3))
                        BEGIN
                            select @OrdersNumAllowed_StatusChange = 1
                        end

                    IF (@OrdersNumAllowed_StatusChange is not null)
                        BEGIN
                            DECLARE @OrdersNumExisting_StatusChange INT = 0
                            if(@Path_Id is null)
                                BEGIN
                                    select @OrdersNumExisting_StatusChange = count(*) from Production_Plan where Path_Id is NULL AND PP_Status_Id = @PP_Status_Id
                                end
                            ELSE
                                BEGIN
                                    select @OrdersNumExisting_StatusChange = count(*) from Production_Plan where Path_Id = @Path_Id AND PP_Status_Id = @PP_Status_Id
                                end
                            If (@OrdersNumExisting_StatusChange >= @OrdersNumAllowed_StatusChange)
                                BEGIN
                                    SELECT Error = 'ERROR: Maximum number of Process orders configured for the path with given status has reached', Code = 'POConflict', ErrorType = 'InvalidStatusTransition', PropertyName1 = 'PP_Status_Id', PropertyName2 = 'PathId', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @PP_Status_Id, PropertyValue2 = @Path_Id, PropertyValue3 = '', PropertyValue4 = ''
                                    RETURN
                                end
                        end

                    /* Now check for status id, if it is an status change to the already present check if it is an valid transition odf status */
                    /* check for any invalid changes */

                    IF (@Path_Id is not NULL AND NOT EXISTS(select 1 from Production_Plan_Status where Path_Id = @Path_Id AND From_PPStatus_Id = @OldStatusId AND To_PPStatus_Id  = @PP_Status_Id))
                        BEGIN
                            SELECT Error = 'ERROR: Invalid status transition', Code = 'InvalidData', ErrorType = 'InvalidStatusTransition', PropertyName1 = 'PP_Status_Id', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @PP_Status_Id, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                            RETURN
                        END

                    /*
                     If we are going to set this to active, we need to check if schedule point unit is available or not, all three flows should start at schedule point unit on setting them to active
                     */

                    /* Now for transition to Active we need to check if required units are available for execution */
                    /* Currently checking it by force, refer to fnPO_CheckProcessOrderTrans for that logic */

                    -- If we are changing status to active we need to check if it is possible to make it active, [Is the unit busy with other active POs]
                    -- we should check this even for unbounded PO. currently it is not so in thick client
                    if(@PP_Status_Id = 3 AND @Path_Id is not null)
                        BEGIN
                            select @statusTransPerm = [dbo].fnPO_CheckProcessOrderTrans(@PP_Id, 1)
                            IF(@statusTransPerm = 0)
                                BEGIN
                                    SELECT Error = 'ERROR: Invalid status transition, Units are already Occupied', Code = 'POConflict', ErrorType = 'UnitsUnavailableForTransition', PropertyName1 = 'PP_Status_Id', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @PP_Status_Id, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                                    RETURN
                                end
                        END
                end



            /*
                only pending can be re-prioritized
            */
            If(@OldStatusId != 1 AND @TransitionDirection is not null)
                BEGIN
                    SELECT Error = 'ERROR: Re-Prioritization only allowed for pending process orders', Code = 'InvalidData', ErrorType = 'InvalidTransition', PropertyName1 = 'TransitionDirection', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @TransitionDirection, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                END
            /*
             Transition direction can only be +1 or -1
             */
            IF  (@TransitionDirection is not null AND @TransitionDirection != 1 AND @TransitionDirection != -1)
                BEGIN
                    SELECT Error = 'ERROR: Invalid TransitionDirection', Code = 'InvalidData', ErrorType = 'InvalidTransition', PropertyName1 = 'TransitionDirection', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @TransitionDirection, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                END





        END

    ---------------------------------------------------------------------------------------
------------------------ Validations for Add ---------------------------------------------------
    ---------------------------------------------------------------------------------------
    IF (@TransType = 1)
        BEGIN
            -- Expensive check
            IF EXISTS(SELECT 1 FROM Production_Plan WHERE Path_Id = @Path_Id   AND Process_Order = @Process_Order)
                OR EXISTS (SELECT 1 FROM Production_Plan WHERE Path_Id IS NULL   AND Process_Order = @Process_Order AND @Path_Id IS NULL)
                BEGIN
                    SELECT Error = 'ERROR: Process Order Name not Unique for the given path', Code = 'POConflict', ErrorType = 'PONameAlreadyUsed', PropertyName1 = 'Process_Order', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Process_Order, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                END
            /* initial status Id should always be pending(1)*/
            IF(@PP_Status_Id != 1)
                BEGIN
                    SELECT Error = 'ERROR: Invalid Initial Status Id', Code = 'InvalidData', ErrorType = 'InvalidStatusId', PropertyName1 = 'PP_Status_Id', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @PP_Status_Id, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                END

        END

    -- Validation for add & rework
    IF (@TransType = 1 AND @PP_Type_Id =2)
        BEGIN
            DECLARE @Old_Source_PP_Status_Id int;
            SELECT @SourcePPId = PP_Id, @Old_Source_PP_Status_Id = PP_Status_Id  from Production_Plan WHERE PP_ID = @Source_PP_ID_INPUT

            IF(@SourcePPId is NULL)
                BEGIN
                    SELECT Error = 'ERROR: Source Process Order not found', Code = 'ResourceNotFound', ErrorType = 'SourceProcessOrderNotFound', PropertyName1 = 'Source_PP_ID', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Source_PP_ID_INPUT, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                END
            IF (Coalesce(@Old_Source_PP_Status_Id, -100) <>4)
                BEGIN
                    SELECT Error = 'ERROR: Source Process Order is Not Completed Status', Code = 'InvalidData', ErrorType = 'InvalidStatusId', PropertyName1 = 'PP_Status_Id', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Process_Order, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                END
        END
    -- This check is not required for now, since we are not using userId in the sproc
    /*
	IF NOT EXISTS(SELECT 1 FROM Users_Base WHERE User_id = @User_Id )
        BEGIN
            --SELECT  Error = 'ERROR: Valid User Required'
            SELECT Error = 'ERROR: Valid User Required', Code = 'InsufficientPermission', ErrorType = 'ValidUserNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            RETURN
        END

     */

--All the validations are done , so beginning a transaction so that we can rollback on each step in case if there is an error
    --BEGIN TRANSACTION


    /*
     First bind/unbind should be done. Start Operation for PO Bind/Unbind
     */
    IF(@TransType = 2 AND COALESCE(@Path_Id, -100)  <> COALESCE(@OldPath_Id, -100))
        BEGIN
            -- 96 transNum is for Bind/Unbind
            set @TransNum = 96

            EXECUTE @return_value = spServer_DBMgrUpdProdPlan
                                    @PP_Id OUTPUT, @TransType, @TransNum, @Path_Id, @CommentId_Final, NULL, @ImpliedSequence OUTPUT, NULL, NULL, NULL, @User_Id, NULL, NULL, NULL, NULL, @EntryOn OUTPUT,
                                    NULL, NULL, NULL, NULL, @Process_Order, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @InsertIntoPendingResultSet
            If(@@ERROR >0)
                BEGIN
                    SELECT Error = 'ERROR in core sproc call spServer_DBMgrUpdProdPlan, return val = ' + CONVERT(varchar, @return_value), Code = 'ERROR', ErrorType = 'ERROR', PropertyName1 = 'ReturnValue', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @return_value, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    --  ROLLBACK TRANSACTION
                    RETURN
                END
        END


    /*
     Start Operation for normal update
     */
    If(@TransType = 2 AND @IsNormalUpdate = 1)
        BEGIN

            set @TransNum = 2
            -- If status is is changed, use old one in this request, will update statusId in next request

            -- Now allowing multiple type updates at the same time

            EXECUTE @return_value = spServer_DBMgrUpdProdPlan
                                    @PP_Id OUTPUT, @TransType, @TransNum, @Path_Id, @CommentId_Final, @Prod_Id, @ImpliedSequence OUTPUT, @OldStatusId, @PP_Type_Id, @SourcePPId, @User_Id, @ParentPPId,
                                    @Control_Type, @PlannedStartTime, @PlannedEndTime, @EntryOn OUTPUT, @Forecast_Quantity, @Production_Rate, @AdjustedQuantity, @Block_Number, @Process_Order,
                                    @TransactionTime, NULL, NULL, NULL, NULL, @BOM_Formulation_Id, @User_General_1, @User_General_2, @User_General_3, @Extended_Info, @InsertIntoPendingResultSet


            If(@@ERROR >0 )
                BEGIN
                    SELECT Error = 'ERROR in core sproc call spServer_DBMgrUpdProdPlan, return val = ' + CONVERT(varchar, @return_value), Code = 'ERROR', ErrorType = 'ERROR', PropertyName1 = 'ReturnValue', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @return_value, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    -- ROLLBACK TRANSACTION
                    RETURN
                END
            /*
			/* check for the Comment_Id here as well, need to see if some issues are there*/
            If(@Comment_Id is Not NULL)
                BEGIN
                    if(@OldComment_Id is NULL)
                        UPDATE Production_Plan SET Comment_Id = @Comment_Id WHERE PP_Id = @PP_Id;
                    /* insert the Comment_Id into the Production Plan Table */
                END

             */


        END




    /*
     Start Operation for status transition
     Do the status transition if required and possible
     */
    IF(@TransType = 2 AND @PP_Status_Id != @OldStatusId)
        BEGIN

            /* for status change next is 2, just send ProcessOrder Name, PPID, @TransType = 2,
                    @TransNum = 97,
                    @Path_Id, StatusId, UserId*/
            set @TransNum = 97

            EXECUTE @return_value = spServer_DBMgrUpdProdPlan
                                    @PP_Id OUTPUT, @TransType, @TransNum, @Path_Id, @CommentId_Final, NULL, @ImpliedSequence OUTPUT, @PP_Status_Id, NULL, NULL, @User_Id, NULL, NULL, NULL, NULL, @EntryOn OUTPUT,
                                    NULL, NULL, NULL, NULL, @Process_Order, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @InsertIntoPendingResultSet

            If(@@ERROR > 0 )
                BEGIN
                    SELECT Error = 'ERROR in core sproc call spServer_DBMgrUpdProdPlan, return val = ' + CONVERT(varchar, @return_value), Code = 'ERROR', ErrorType = 'ERROR', PropertyName1 = 'ReturnValue', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @return_value, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    --ROLLBACK TRANSACTION
                    RETURN
                END
        END

    /*
     Start Operation for reordering of PO
     */
    IF(@TransType = 2 AND @TransitionDirection is NOT NULL)
        BEGIN


            if(@TransitionDirection = 1)
                set @TransNum = 99
            else if (@TransitionDirection = -1)
                set @TransNum = 98


            EXECUTE @return_value = spServer_DBMgrUpdProdPlan
                                    @PP_Id OUTPUT, @TransType, @TransNum, @Path_Id, @CommentId_Final, NULL, @ImpliedSequence OUTPUT, NULL, NULL, NULL, @User_Id, NULL, NULL, NULL, NULL, @EntryOn OUTPUT,
                                    NULL, NULL, NULL, NULL, @Process_Order, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @InsertIntoPendingResultSet
            If(@@ERROR > 0 )
                BEGIN
                    SELECT Error = 'ERROR in core sproc call spServer_DBMgrUpdProdPlan, return val = '+ CONVERT(varchar, @return_value), Code = 'ERROR', ErrorType = 'ERROR', PropertyName1 = 'ReturnValue', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @return_value, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    --ROLLBACK TRANSACTION
                    RETURN
                END
        END








    /*
     Start Operation for PO delete
     */
    IF(@TransType = 3)
        BEGIN

            set @TransNum = 2
            EXECUTE @return_value = spServer_DBMgrUpdProdPlan
                                    @PP_Id OUTPUT, @TransType, @TransNum, @OldPath_Id, NULL, NULL, @ImpliedSequence_Old OUTPUT, NULL, NULL, NULL, @User_Id, NULL, NULL, NULL, NULL, @EntryOn_Old OUTPUT, NULL,
                                    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @InsertIntoPendingResultSet
            If(@@ERROR > 0)
                BEGIN
                    SELECT Error = 'ERROR in core sproc call spServer_DBMgrUpdProdPlan, return val = '+ CONVERT(varchar, @return_value), Code = 'ERROR', ErrorType = 'ERROR', PropertyName1 = 'ReturnValue', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @return_value, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    --ROLLBACK TRANSACTION
                    RETURN
                END
        END

    /*
     Start Operation for PO ADD
     */
    If(@TransType = 1)
        BEGIN
            set @TransNum = 2

            EXECUTE @return_value = spServer_DBMgrUpdProdPlan
                                    @PP_Id OUTPUT, @TransType, @TransNum, @Path_Id, @CommentId_Final, @Prod_Id, @ImpliedSequence OUTPUT, @PP_Status_Id, @PP_Type_Id, @SourcePPId, @User_Id, @ParentPPId, @Control_Type,
                                    @PlannedStartTime, @PlannedEndTime, @EntryOn OUTPUT, @Forecast_Quantity, @Production_Rate, @AdjustedQuantity, @Block_Number, @Process_Order, @TransactionTime, NULL, NULL,
                                    NULL, NULL, @BOM_Formulation_Id, @User_General_1, @User_General_2, @User_General_3, @Extended_Info, @InsertIntoPendingResultSet
            If(@@ERROR > 0)
                BEGIN
                    SELECT Error = 'ERROR in core sproc call spServer_DBMgrUpdProdPlan, return val = ' + CONVERT(varchar, @return_value), Code = 'ERROR', ErrorType = 'ERROR', PropertyName1 = 'ReturnValue', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @return_value, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    --ROLLBACK TRANSACTION
                    RETURN
                END
            SELECT @PO_ID_ADDED = @PP_Id
            /*
            If(@Comment_Id is Not NULL)
                BEGIN
                    if(@OldComment_Id is NULL)
                        UPDATE Production_Plan SET Comment_Id = @Comment_Id WHERE PP_Id = @PP_Id;
                    /* insert the Comment_Id into the Production Plan Table */
                END
             */

        END

    -- Avoiding history record for binding and unbinding
DECLARE @Actual_Good_Quantity_Val float
SELECT @Actual_Good_Quantity_Val = Actual_Good_Quantity from Production_Plan where PP_ID = @PP_Id
    if(@TransType <> 3 AND (COALESCE(@Path_Id, -100) = COALESCE(@OldPath_Id, -100) OR (COALESCE(@Path_Id, -100) <> COALESCE(@OldPath_Id, -100) AND @Actual_Good_Quantity_Val is null)))
        BEGIN
            /*
             If transaction type is not three then call the spServer_DBMgrUpdProdStats to update the predicted quantities
             */
            create table #ProdStatsValues
            (
                dummy1 int, dummy2 int, dummy3 int, dummy4 int, dummy5 int,
                StatType int, Id int, StartTime DateTime, EndTime DatetIme, GoodItems int, BadItems int,RunningMinutes float,
                DownMinutes float, GoodQuantity float, BadQuantity float,
                PredictedTotalDuration float, PredictedRemainingDuration float, PredictedRemainingQuantity float, AlarmCount int, LateItems int, Repetitions int
            )

--- Declare variables to store the values from table to pass them to spServer_DBMgrUpdProdStats, couldn't pass them directly
            DECLARE @StatTypeStats int, @IdStats int, @StartTimeStats DateTime, @EndTimeStats DatetIme, @GoodItemsStats int, @BadItemsStats int, @RunningMinutesStats float,
                @DownMinutesStats float, @GoodQuantityStats float, @BadQuantityStats float,
                @PredictedTotalDurationStats float, @PredictedRemainingDurationStats float, @PredictedRemainingQuantityStats float, @AlarmCountStats int, @LateItemsStats int, @RepetitionsStats int


            INSERT INTO #ProdStatsValues EXEC spServer_SchMgrCalcStats @PP_Id,
                                              @ParentPPId = @ParentPPId OUTPUT
            --Update the stats only if we get some values in this table
            IF(SELECT COUNT(1) FROM #ProdStatsValues) = 1
                BEGIN

                    Select @StatTypeStats = StatType, @IdStats = Id, @StartTimeStats = StartTime, @EndTimeStats = EndTime, @GoodItemsStats = GoodItems, @BadItemsStats  = BadItems,
                           @RunningMinutesStats = RunningMinutes, @DownMinutesStats = DownMinutes, @GoodQuantityStats = GoodQuantity, @BadQuantityStats = BadQuantity,
                           @PredictedTotalDurationStats = PredictedTotalDuration, @PredictedRemainingDurationStats = PredictedRemainingDuration, @PredictedRemainingQuantityStats = PredictedRemainingQuantity,
                           @AlarmCountStats = AlarmCount, @LateItemsStats = LateItems, @RepetitionsStats = Repetitions from #ProdStatsValues
                    -- Insert the output of stored procedures into temp table
                    /*
                     Only TransType 2 is supported [update of PO from spServer_DBMgrUpdProdStats, see the sproc]
                     default value of @TransNum will be used [2], it will throw error if transNum is not in (0,2,1010, NULL)
                     Need to check when to pass transNum 2 [most probably will be used for parentProcessOrder
                     */
                    EXEC	@return_value = [dbo].[spServer_DBMgrUpdProdStats]
                                            2, 0, @StatTypeStats , @PP_Id, @StartTimeStats, @EndTimeStats, @GoodItemsStats, @BadItemsStats, @RunningMinutesStats,
                                            @DownMinutesStats, @GoodQuantityStats, @BadQuantityStats, @PredictedTotalDurationStats,
                                            @PredictedRemainingDurationStats,
                                            @PredictedRemainingQuantityStats, @AlarmCountStats, @LateItemsStats, @RepetitionsStats, @PPId = @PP_Id OUTPUT, @ParentPPId = @ParentPPId OUTPUT, @InsertIntoPendingResultSet =1

                    If(@@ERROR > 0)
                        BEGIN
                            SELECT Error = 'ERROR in core sproc call spServer_DBMgrUpdProdStats, return val = ' + CONVERT(varchar, @return_value), Code = 'ERROR', ErrorType = 'ERROR', PropertyName1 = 'ReturnValue', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @return_value, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                            --ROLLBACK TRANSACTION
                            --DROP TABLE #ProdStatsValues;
                            RETURN
                        END
                END

            --DROP TABLE #ProdStatsValues;

        END

--IF we reach here no errors so far we can commit this transaction
--COMMIT TRANSACTION

