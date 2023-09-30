CREATE PROCEDURE dbo.spCSS_InsertDeleteComment
@KeyId BigInt,
@Table int,
@UserId int,
@CommentSource int,
@AddlInfo nVarChar(255), --Use for additional key info.
@NewId int OUTPUT   --If 0, this is a new comment & the ID is sent back here, else this ID is used to delete the comment
AS
Declare 
  @Delete bit, 
  @CommentId int  
Select @Delete = 
 CASE 
   WHEN @NewId = 0 THEN 0 
   WHEN @NewId is NULL THEN 0 
   ELSE 1 
 END
begin transaction
If @Delete = 0 
  begin
    Select @NewId = 0 
    Insert Into Comments (Comment, Comment_Text, User_Id, Modified_On, CS_Id) 
     values (' ', ' ', @UserId, dbo.fnServer_CmnGetDate(getutcdate()), @CommentSource)
    Select @NewId = Scope_Identity(), @CommentId = NULL 
  end
Else
  Select @CommentId = @NewId
print convert(nvarchar(25),@commentid)
If (@KeyId<>0) 
 begin 
  if @Table = 1 --Tests
    begin
      update tests set Comment_id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where test_id = @KeyId and (Comment_Id is null or Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
  else if @Table = 2  --Variables
    begin
      Update Variables_Base set Comment_id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where var_id = @KeyId and (Comment_Id is null or Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
  else if @Table = 3  --Product
   begin
      update products set Comment_id =
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where prod_id = @KeyId and (Comment_Id is null or Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
  else if @Table = 4 --Event
    begin
      update events set Comment_id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where event_id = @KeyId and (Comment_Id is null or Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
  else if @Table = 5 --Sheet column
    begin
     update sheet_columns set Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
       where sheet_id = @KeyId and result_on = CONVERT(DATETIME, @AddlInfo) and (Comment_Id is null or Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
  else if @Table = 6 --Alarm Templates
    begin
      update Alarm_Templates set Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where AT_id = @KeyId and (Comment_Id is null or Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
  else if @Table = 7 --Alarm Templates Variable Data
    begin
      update Alarm_Template_Var_Data set Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where ATD_id = @KeyId and (Comment_Id is null or Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
  else if @Table = 8 --Prod Units
    begin
      update Prod_Units set Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where PU_id = @KeyId and (Comment_Id is null or Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
  else if @Table = 9 --UDE Comment_id
    begin
      update User_Defined_Events set Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where UDE_id = @KeyId and (Comment_Id is null or Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
  else if @Table = 10 --UDE Cause_Comment_Id
    begin
      update User_Defined_Events set Cause_Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where UDE_id = @KeyId and (Cause_Comment_Id is null or Cause_Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
  else if @Table = 11 --UDE Action_Comment_Id
    begin
      update User_Defined_Events set  Action_Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where UDE_id = @KeyId and (Action_Comment_Id is null or Action_Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
  else if @Table = 12 --UDE Research_Comment_Id
    begin
      update User_Defined_Events set Research_Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where UDE_id = @KeyId and (Research_Comment_Id is null or Research_Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
  else if @Table = 13 --Alarms Cause_Comment_Id
    begin
      update Alarms set Cause_Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where Alarm_id = @KeyId and (Cause_Comment_Id is null or Cause_Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
  else if @Table = 14 --Alarms Action_Comment_Id
    begin
      update Alarms set Action_Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where Alarm_id = @KeyId and (Action_Comment_Id is null or Action_Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
  else if @Table = 15 --Alarms Research_Comment_Id
    begin
      update Alarms set Research_Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where Alarm_id = @KeyId and (Research_Comment_Id is null or Research_Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
  else if @Table = 16 --Downtime Cause_Comment_Id
    begin
      update Timed_Event_Details set Cause_Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where TEDet_id = @KeyId and (Cause_Comment_Id is null or Cause_Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	  	 
  else if @Table = 17 --Downtime Action_Comment_Id
    begin
      update Timed_Event_Details set Action_Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where TEDet_id = @KeyId and (Action_Comment_Id is null or Action_Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	  	 
  else if @Table = 18 --Downtime Research_Comment_Id
    begin
      update Timed_Event_Details set Research_Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where TEDet_id = @KeyId and (Research_Comment_Id is null or Research_Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	  	 
  else if @Table = 19 --Product Change Comment_Id
    begin
      update Production_Starts set Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where Start_id = @KeyId and (Comment_Id is null or Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
  else if @Table = 20 --Waste Cause_Comment_Id
    begin
      update Waste_Event_Details set Cause_Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where WED_id = @KeyId and (Cause_Comment_Id is null or Cause_Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
  else if @Table = 21 --Waste Action_Comment_Id
    begin
      update Waste_Event_Details set Action_Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where WED_id = @KeyId and (Action_Comment_Id  is null or Action_Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
  else if @Table = 22 --Waste Research_Comment_Id
    begin
      update Waste_Event_Details set Research_Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where WED_id = @KeyId and (Research_Comment_Id is null or Research_Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
--  else if @Table = 23 --Event_Config.Comment_Id
--    begin
--     update Event_Config set Comment_Id = 
--        CASE 
--          WHEN @Delete = 1 THEN NULL 
--          ELSE @NewId 
--        END
--        where EC_id = @KeyId and (Comment_Id is null or Comment_Id = @CommentId)
--      if @@ROWCOUNT = 0 
--        begin
--          ROLLBACK TRANSACTION
--          GOTO Failed
--        end
--    end 	 
  else if @Table = 24 --ED_Models.Comment_Id
    begin
      update ED_Models set Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where ED_Model_Id = @KeyId and (Comment_Id is null or Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
  else if @Table = 25 --Calculations
    begin
      update Calculations set Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where Calculation_ID = @KeyId and (Comment_Id is null or Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
  else if @Table = 26 --Event_Subtypes
    begin
      update Event_SubTypes set Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where Event_Subtype_Id = @KeyId and (Comment_Id is null or Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
 else if @Table = 27 --Event_Configuration
    begin
      update Event_Configuration set Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where EC_Id = @KeyId and (Comment_Id is null or Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
 else if @Table = 28 --Customer Orders
    begin
      update Customer_Orders set Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where Order_Id = @KeyId and (Comment_Id is null or Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
 else if @Table = 29 --Customer Order Line Items
    begin
      update Customer_Order_Line_Items set Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where Order_Line_Id = @KeyId and (Comment_Id is null or Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
 else if @Table = 30 --ED_Fields
    begin
      update ED_Fields set Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where ED_Field_Id = @KeyId and (Comment_Id is null or Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
--------------begin mason's addition 08/22/00
 else if @Table = 31 --Complaint_Comment
    begin
      update Complaints set Complaint_Comment = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where Complaint_Id = @KeyId and (Complaint_Comment is null or Complaint_Comment = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
 else if @Table = 32 --Complaint_Research_Comment
    begin
      update Complaints set Research_Comment = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where Complaint_Id = @KeyId and (Research_Comment is null or Research_Comment = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
 else if @Table = 33 --Complaint_Response_Comment
    begin
      update Complaints set Response_Comment = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where Complaint_Id = @KeyId and (Response_Comment is null or Response_Comment = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
 else if @Table = 34 --Complaint_Details_Comment
    begin
      update Complaint_Details set Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where Complaint_Detail_Id = @KeyId and (Comment_Id is null or Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
 else if @Table = 35 --Production_Plan
    begin
      update Production_Plan set Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where PP_Id = @KeyId and (Comment_Id is null or Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
--------------end mason's addition 08/22/00 	 
--------------begin molly's addition 08/03/01
else if @Table = 36 --Characteristics
    begin
      update Characteristics set Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where Char_ID = @KeyId and (Comment_Id is null or Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
else if @Table = 37 --Production Lines
    begin
      update Prod_Lines set Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where PL_ID = @KeyId and (Comment_Id is null or Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	   
else if @Table = 38 --Production Groups
    begin
      update PU_Groups set Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where PUG_ID = @KeyId and (Comment_Id is null or Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
else if @Table = 39 --Security Groups
    begin
      update Security_Groups set Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where Group_ID = @KeyId and (Comment_Id is null or Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
else if @Table = 40 --Specifications
    begin
      update Specifications set Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where Spec_ID = @KeyId and (Comment_Id is null or Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
--------------end molly's addition 08/03/01 	 
 else if @Table = 41 --Production_Setup
    begin
      update Production_Setup set Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where PP_Setup_Id = @KeyId and (Comment_Id is null or Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 42 --Production_Setup_Detail
    begin
      update Production_Setup_Detail set Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where PP_Setup_Detail_Id = @KeyId and (Comment_Id is null or Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 43 --Crew Schedule
    begin
      update Crew_Schedule set Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where CS_Id = @KeyId and (Comment_Id is null or Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 55 -- Product Family (for SDK)
    begin
      update Product_Family set Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where Product_Family_Id = @KeyId and (Comment_Id is null or Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 56 -- Product Property (for SDK)
    begin
      update Product_Properties set Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where Prop_Id = @KeyId and (Comment_Id is null or Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 57 --Production Plan Starts (for SDK)
    begin
      update Production_Plan_Starts set Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where PP_Start_Id = @KeyId and (Comment_Id is null or Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 71 -- Variable Specification (for SDK)
    begin
      update Var_Specs set Comment_Id = 
        CASE 
          WHEN @Delete = 1 THEN NULL 
          ELSE @NewId 
        END
        where VS_Id = @KeyId and (Comment_Id is null or Comment_Id = @CommentId)
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 99 --ESignature comment
    begin
      select @NewId = @NewId
    end
else 
    begin
      ROLLBACK TRANSACTION
      GOTO Failed
    end 
 end
If @Delete = 1 
  begin
    Update Comments Set Comment = '', Comment_Text = '', ShouldDelete = 1 Where Comment_Id = @CommentId
  end
commit transaction
RETURN
Failed:
Select @NewId = 0 
RETURN
