CREATE FUNCTION dbo.fnPO_CheckProcessOrderTrans(@PPId int, @IsForced int)
    RETURNS int
    AS
        /***********************************************************/
        /******** Copyright 2019 GE Fanuc International Inc.********/
        /****************** All Rights Reserved ********************/
        /***********************************************************/
        /*based on spSV_CheckProcessOrderTrans, but here return and logic is a little bit different. */
        /*
            All units simultaneous:
            Transition Not Allowed Because Units Running Active Order On Another Path.

            Independent:
            Not All Units Required For This Order Are Currently Available.  Proceed Anyway?


            Flow by Event:


            Current Logic in UCC implementation:
            for All units simultaneous:
            Transition Not Allowed Because Units Running Active Order On Another Path.

            Independent:
            If schedule Unit is active somewhere then reject
            if other units is active then allow to create using the prompt
            Not All Units Required For This Order Are Currently Available.  Proceed Anyway?

        */


    BEGIN
            Declare @PathId int,
            @ret int = 1;  --- 0 if transition is not allowed

                /*
                    When activating a process order we need to do a unit "binding" check.
                    In other words, we need to check if all units that are required in the execution path of the order are either already running on that same path,
                    or are not running another order.  I think the logic would go something like this:
                    Before going active:
                */
            --1. What is the path of this order?
            select @PathId = Path_Id
                 from Production_Plan
                 where PP_Id = @PPId
            --2. What units are in this path?
            Declare @PathUnits table (PU_Id int, ThisPath_PPStartId int NULL, OtherPath_PPStartId int NULL, isScheduleUnit int NULL)
            INSERT INTO @PathUnits
              Select PU_Id, NULL, NULL, Is_Schedule_Point
                From PrdExec_Path_Units
                     Where Path_Id = @PathId
            --3. Are all units already on this path?
                -- this is not required mostly, since we are checking for the status on the unit for this PP, which is not started, so basically this will do nothing
                -- keeping it here to handle negative cases
            Update @PathUnits
                Set ThisPath_PPStartId = (Select PP_Start_Id From Production_Plan_Starts Where PP_Id = @PPId and PU_Id = [@PathUnits].PU_Id and End_Time is NULL)

            --4. If not; are there units which are active from other processorders [AnyPath]
            Update @PathUnits
                 Set OtherPath_PPStartId = (Select PP_Start_Id From Production_Plan_Starts Where PP_Id <> @PPId and PU_Id = [@PathUnits].PU_Id and End_Time is NULL)
                 Where ThisPath_PPStartId is NULL

                --Schedule Control Types
                -- 0 = All Units Run Same Schedule Simultaneously
                -- 1 = Schedule Flows By Event
                -- 2 = Schedule Flows Independently

            -- 5. Transition Not Allowed if another Processorder is active on anyunits of this PO
            --		If it is an 0- Schedule Control Type. Because all units are going to run at the same time
            If (Select Count(*) From @PathUnits Where OtherPath_PPStartId is NOT NULL) > 0 and (Select Schedule_Control_Type From PrdExec_Paths Where Path_Id = @PathId) = 0
                Select @ret = 0
            -- 6. Transition Not Allowed if another Processorder is active on schedule unit of this PO
            --		If it is an 2 - Schedule Control Type. Because we can't start th PO on it's first unit[Schedule unit] since it is already occupied by other unit
            --		for Schedule Flows Independently we are only concerned with the unit order is currently running and at the time of start order will only run on schedule unit
            If ( Select Count(*) From @PathUnits Where isScheduleUnit = 1 AND OtherPath_PPStartId is NOT NULL) > 0 and (Select Schedule_Control_Type From PrdExec_Paths Where Path_Id = @PathId) = 3
                Select @ret = 0

            -- 7. Transition Not Allowed if another Processorder is active on any unit of this PO, User should be notified of this issue that another PO is using some of units which will be required in future for this PO
                    -- If user still want to procced then we will allow it since it is possible
            --		If it is an 2 - Schedule Control Type. Because we can't start th PO on it's first unit[Schedule unit] since it is already occupied by other unit
            --		for Schedule Flows Independently we are only concerned with the unit order is currently running and at the time of start order will only run on schedule unit
            -- But since we are allowing for overlap, we will need to check the transition od PO in units for independent flow
            If @IsForced  = 0 AND (Select Count(*) From @PathUnits Where isScheduleUnit = 1 AND OtherPath_PPStartId is NOT NULL) > 0 and (Select Schedule_Control_Type From PrdExec_Paths Where Path_Id = @PathId) = 3
                Select @ret = 0

            -- 8. TODO For flow by event Keeping it default
            -- need to make some changes later
            If (Select Count(*) From @PathUnits Where OtherPath_PPStartId is NOT NULL) > 0 and (Select Schedule_Control_Type From PrdExec_Paths Where Path_Id = @PathId) = 2
                Select @ret = 0

        RETURN @ret;
END;

