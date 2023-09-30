CREATE PROCEDURE dbo.[spCSS_InsertDeleteChainedComment_Bak_177]
@KeyId nvarchar(100),
@Table int,
@UserId int,
@CommentSource int,
@AddlInfo nVarChar(255), --Use for additional key info.
@AddlInfo2 nVarChar(255), --Use for additional key info.
@NewId int OUTPUT,  --If 0, this is a new comment & the ID is sent back here, else this ID is used to delete the comment
@CurrentTopOfChainId int OUTPUT --Top of comment chain for this comment
  AS 
/***********************************************************/
/******** Copyright 2004 GE Fanuc International Inc.********/
/****************** All Rights Reserved ********************/
/***********************************************************/
Declare 
 	 @Delete bit, 
 	 @CommentId int,
 	 @TopOfChainId int,
 	 @NextCommentId int,
 	 @PrevCommentId int,
 	 @DeletedTop int,
 	 @ColumnDate DateTime,
 	 @BIKeyId Bigint
SET @BIKeyId = convert(bigint,@KeyId) 	 
IF @AddlInfo = '' SET @AddlInfo = Null
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
    Insert Into Comments (Comment, Comment_Text, User_Id, Entry_On, CS_Id, Modified_On) 
     values (' ', ' ', @UserId, dbo.fnServer_CmnGetDate(getutcdate()), @CommentSource, dbo.fnServer_CmnGetDate(getutcdate()))
    Select @NewId = Scope_Identity(), @CommentId = NULL 
    --Default TopOfChain to the new comment
    Select @TopOfChainId = @NewId
  end
Else
  Select @CommentId = @NewId
Select @DeletedTop = 0
If @Delete = 1 
  begin
    Select @TopOfChainId = TopOfChain_Id, @NextCommentId = NextComment_Id From Comments Where Comment_Id = @CommentId
    If @TopOfChainId = @CommentId --Removing the first comment in a possible Chain
      Begin
        Select @DeletedTop = 1
        If Not @NextCommentId is NULL --Update the TopOfChain for all related comments the point to the new TopOfChain
          Begin
            Update Comments Set TopOfChain_Id = @NextCommentId Where TopOfChain_Id = @CommentId
            Select @TopOfChainId = @NextCommentId
          End
        Else
          Select @TopOfChainId = NULL --Removing the only comment in the chain
      End
    Else
      If Not @NextCommentId is NULL  --Removing a comment in the middle of a Chain
        Begin
          Update Comments Set NextComment_Id = @NextCommentId Where NextComment_Id = @CommentId
        End
      Else
        Update Comments Set NextComment_Id = NULL Where NextComment_Id = @CommentId --Removing the last comment in the chain
  end
If (@BIKeyId<>0) 
 begin 
  if @Table = 1 --Tests
    begin
      select @TopOfChainId = 
        CASE 
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Tests Where test_id = @BIKeyId)
        END
      update tests set Comment_id = @TopOfChainId
        where test_id = @BIKeyId
 	   DECLARE @tempRowCount INT = @@ROWCOUNT
      --To update the activity table, if the test is of type comment during the first comment addition or last comment deletion
 	   -- Below will only work if ts called at this place
 	   EXEC spServer_DBMgrUpdCommentTestActivity @BIKeyId, @Delete, @UserId
      if @tempRowCount = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
  else if @Table = 2  --Variables
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from variables where var_id = @BIKeyId)
        END
      Update Variables_Base set Comment_id = @TopOfChainId
        where var_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
  else if @Table = 3  --Product
   begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from products where prod_id = @BIKeyId)
        END
      update products set Comment_id = @TopOfChainId
        where prod_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
  else if @Table = 4 --Event
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from events where event_id = @BIKeyId)
        END
      update events set Comment_id = @TopOfChainId
        where event_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
  else if @Table = 5 --Sheet columns
 	 BEGIN
 	  	 If @AddlInfo is null
 	  	 BEGIN
 	  	  	 If @DeletedTop = 1
 	  	  	  	 Select @ColumnDate = Max(result_on) from sheet_columns where sheet_Id = @BIKeyId and comment_Id = @CommentId
 	  	  	 Else
 	  	  	  	 Select @ColumnDate = Max(result_on) from sheet_columns where sheet_Id = @BIKeyId and comment_Id = @TopOfChainId
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 SET @ColumnDate = CONVERT(DATETIME, @AddlInfo)
 	  	 END
 	  	 SELECT @TopOfChainId =  	 CASE 	 WHEN @Delete = 1 THEN @TopOfChainId
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 ELSE (Select Coalesce(Comment_Id, @TopOfChainId) 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 from sheet_columns where sheet_id = @BIKeyId and result_on =  @ColumnDate)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 END
 	  	 UPDATE sheet_columns set Comment_Id = @TopOfChainId where sheet_id = @BIKeyId and result_on =  @ColumnDate
 	  	 if @@ROWCOUNT = 0 
 	  	 BEGIN
 	  	  	 ROLLBACK TRANSACTION
 	  	  	 GOTO Failed
 	  	 END
 	 END
  else if @Table = 6 --Alarm Templates
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Alarm_Templates where at_id = @BIKeyId)
        END
      update Alarm_Templates set Comment_Id = @TopOfChainId
        where AT_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
  else if @Table = 7 --Alarm Templates Variable Data
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Alarm_Template_Var_Data where atd_id = @BIKeyId)
        END
      update Alarm_Template_Var_Data set Comment_Id = @TopOfChainId
        where ATD_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
  else if @Table = 8 --Prod Units
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Prod_Units where PU_id = @BIKeyId)
        END
      update Prod_Units set Comment_Id = @TopOfChainId
        where PU_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
  else if @Table = 9 --UDE Comment_id
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from User_Defined_Events where UDE_id = @BIKeyId)
        END
      update User_Defined_Events set Comment_Id = @TopOfChainId
        where UDE_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
  else if @Table = 10 --UDE Cause_Comment_Id
    begin
      select @TopOfChainId = 
        CASE 
          WHEN  @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Cause_Comment_Id, @TopOfChainId) from User_Defined_Events where UDE_id = @BIKeyId)
        END
      update User_Defined_Events set Cause_Comment_Id = @TopOfChainId
        where UDE_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
  else if @Table = 11 --UDE Action_Comment_Id
    begin
      select @TopOfChainId = 
        CASE 
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Action_Comment_Id, @TopOfChainId) from User_Defined_Events where UDE_id = @BIKeyId)
        END
      update User_Defined_Events set  Action_Comment_Id = @TopOfChainId
        where UDE_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
  else if @Table = 12 --UDE Research_Comment_Id
    begin
      select @TopOfChainId =
        CASE 
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Research_Comment_Id, @TopOfChainId) from User_Defined_Events where UDE_id = @BIKeyId)
        END
      update User_Defined_Events set Research_Comment_Id = @TopOfChainId
        where UDE_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
  else if @Table = 13 --Alarms Cause_Comment_Id
    begin
      select @TopOfChainId = 
        CASE 
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Cause_Comment_Id, @TopOfChainId) from Alarms where alarm_id = @BIKeyId)
        END
      update Alarms set Cause_Comment_Id = @TopOfChainId
        where Alarm_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
  else if @Table = 14 --Alarms Action_Comment_Id
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Action_Comment_Id, @TopOfChainId) from Alarms where alarm_id = @BIKeyId)
        END
      update Alarms set Action_Comment_Id = @TopOfChainId
        where Alarm_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
  else if @Table = 15 --Alarms Research_Comment_Id
    begin
      select @TopOfChainId = 
        CASE 
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Research_Comment_Id, @TopOfChainId) from Alarms where alarm_id = @BIKeyId)
        END
      update Alarms set Research_Comment_Id = @TopOfChainId
        where Alarm_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
  else if @Table = 16 --Downtime Cause_Comment_Id
    begin
      select @TopOfChainId = 
        CASE 
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Cause_Comment_Id, @TopOfChainId) from Timed_Event_Details where tedet_id = @BIKeyId)
        END
      update Timed_Event_Details set Cause_Comment_Id = @TopOfChainId
        where TEDet_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	  	 
  else if @Table = 17 --Downtime Action_Comment_Id
    begin
      select @TopOfChainId = 
        CASE 
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Action_Comment_Id, @TopOfChainId) from Timed_Event_Details where tedet_id = @BIKeyId)
        END
      update Timed_Event_Details set Action_Comment_Id = @TopOfChainId
        where TEDet_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	  	 
  else if @Table = 18 --Downtime Research_Comment_Id
    begin
      select @TopOfChainId = 
        CASE 
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Research_Comment_Id, @TopOfChainId) from Timed_Event_Details where tedet_id = @BIKeyId)
        END
      update Timed_Event_Details set Research_Comment_Id = @TopOfChainId
        where TEDet_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	  	 
  else if @Table = 19 --Product Change Comment_Id
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Production_Starts where start_id = @BIKeyId)
        END
      update Production_Starts set Comment_Id = @TopOfChainId
        where Start_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
  else if @Table = 20 --Waste Cause_Comment_Id
    begin
      select @TopOfChainId = 
        CASE 
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Cause_Comment_Id, @TopOfChainId) from Waste_Event_Details where WED_id = @BIKeyId)
        END
      update Waste_Event_Details set Cause_Comment_Id = @TopOfChainId
        where WED_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
  else if @Table = 21 --Waste Action_Comment_Id
    begin
      select @TopOfChainId = 
        CASE 
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Action_Comment_Id, @TopOfChainId) from Waste_Event_Details where WED_id = @BIKeyId)
        END
      update Waste_Event_Details set Action_Comment_Id = @TopOfChainId
        where WED_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
  else if @Table = 22 --Waste Research_Comment_Id
    begin
      select @TopOfChainId = 
        CASE 
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Research_Comment_Id, @TopOfChainId) from Waste_Event_Details where WED_id = @BIKeyId)
        END
      update Waste_Event_Details set Research_Comment_Id = @TopOfChainId
        where WED_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
  else if @Table = 24 --ED_Models.Comment_Id
    begin
      select @TopOfChainId = 
        CASE 
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from ED_Models where ED_Model_id = @BIKeyId)
        END
      update ED_Models set Comment_Id = @TopOfChainId
        where ED_Model_Id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
  else if @Table = 25 --Calculations
    begin
      select @TopOfChainId = 
        CASE 
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Calculations where Calculation_id = @BIKeyId)
        END
      update Calculations set Comment_Id = @TopOfChainId
        where Calculation_ID = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
  else if @Table = 26 --Event_Subtypes
    begin
      select @TopOfChainId = 
        CASE 
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Event_Subtypes where Event_Subtype_id = @BIKeyId)
        END
      update Event_SubTypes set Comment_Id = @TopOfChainId
        where Event_Subtype_Id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
 else if @Table = 27 --Event_Configuration
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Event_Configuration where ec_id = @BIKeyId)
        END
      update Event_Configuration set Comment_Id = @TopOfChainId
        where EC_Id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
 else if @Table = 28 --Customer Orders
    begin
      select @TopOfChainId = 
        CASE 
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Customer_Orders where order_id = @BIKeyId)
        END
      update Customer_Orders set Comment_Id = @TopOfChainId
        where Order_Id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
 else if @Table = 29 --Customer Order Line Items
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Customer_Order_Line_Items where order_line_id = @BIKeyId)
        END
      update Customer_Order_Line_Items set Comment_Id = @TopOfChainId
        where Order_Line_Id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
 else if @Table = 30 --ED_Fields
    begin
      select @TopOfChainId = 
        CASE 
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from ED_Fields where ed_field_id = @BIKeyId)
        END
      update ED_Fields set Comment_Id = @TopOfChainId
        where ED_Field_Id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 35 --Production_Plan
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Production_Plan where PP_id = @BIKeyId)
        END
      update Production_Plan set Comment_Id = @TopOfChainId
        where PP_Id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
else if @Table = 36 --Characteristics
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Characteristics where Char_id = @BIKeyId)
        END
      update Characteristics set Comment_Id = @TopOfChainId
        where Char_ID = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
else if @Table = 37 --Production Lines
    begin
      select @TopOfChainId = 
        CASE 
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Prod_Lines where PL_id = @BIKeyId)
        END
      update Prod_Lines set Comment_Id = @TopOfChainId
        where PL_ID = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	   
else if @Table = 38 --Production Groups
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from PU_Groups where PUG_id = @BIKeyId)
        END
      update PU_Groups set Comment_Id = @TopOfChainId
        where PUG_ID = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
else if @Table = 39 --Security Groups
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Security_Groups where Group_id = @BIKeyId)
        END
      update Security_Groups set Comment_Id = @TopOfChainId
        where Group_ID = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
else if @Table = 40 --Specifications
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Specifications where Spec_id = @BIKeyId)
        END
      update Specifications set Comment_Id = @TopOfChainId
        where Spec_ID = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end 	 
 else if @Table = 41 --Production_Setup
    begin
      select @TopOfChainId = 
        CASE
          WHEN  @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Production_Setup where PP_Setup_id = @BIKeyId)
        END
      update Production_Setup set Comment_Id = @TopOfChainId
        where PP_Setup_Id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 42 --Production_Setup_Detail
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Production_Setup_Detail where PP_Setup_Detail_id = @BIKeyId)
        END
      update Production_Setup_Detail set Comment_Id = @TopOfChainId
        where PP_Setup_Detail_Id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 43 --Crew Schedule
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Crew_Schedule where CS_id = @BIKeyId)
        END
      update Crew_Schedule set Comment_Id = @TopOfChainId
        where CS_Id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 44 --Active Specs
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Active_Specs where AS_id = @BIKeyId)
        END
      update Active_Specs set Comment_Id = @TopOfChainId
        where AS_Id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 45 --COA
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from COA where COA_id = @BIKeyId)
        END
      update COA set Comment_Id = @TopOfChainId
        where COA_Id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 46 --COA Items
    begin
      select @TopOfChainId = 
        CASE 
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from COA_Items where COA_Item_id = @BIKeyId)
        END
      update COA_Items set Comment_Id = @TopOfChainId
        where COA_Item_Id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 47 --Container Location
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Container_Location where Container_id = @BIKeyId)
        END
      update Container_Location set Comment_Id = @TopOfChainId
        where Container_Id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 48 --Customer COA
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Customer_COA where Customer_COA_Id = @BIKeyId)
        END
      update Customer_COA set Comment_Id = @TopOfChainId
        where Customer_COA_Id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 49 --Event Details
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Event_Details where Event_Id = @BIKeyId)
        END
      update Event_Details set Comment_Id = @TopOfChainId
        where Event_Id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 50 --Event Reasons
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Event_Reasons where Event_Reason_Id = @BIKeyId)
        END
      update Event_Reasons set Comment_Id = @TopOfChainId
        where Event_Reason_Id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 51 --GB DSet
    begin
      select @TopOfChainId = 
        CASE 
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from GB_DSet where DSet_Id = @BIKeyId)
        END
      update GB_DSet set Comment_Id = @TopOfChainId
        where DSet_Id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 52 --GB RSum
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from GB_RSum where RSum_Id = @BIKeyId)
        END
      update GB_RSum set Comment_Id = @TopOfChainId
        where RSum_Id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 53 --In Process Bins
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from In_Process_Bins where Bin_Id = @BIKeyId)
        END
      update In_Process_Bins set Comment_Id = @TopOfChainId
        where Bin_Id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 54 --PrdExec Input Event
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from PrdExec_Input_Event where Input_Event_Id = @BIKeyId)
        END
      update PrdExec_Input_Event set Comment_Id = @TopOfChainId
        where Input_Event_Id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 55 --Product Family
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Product_Family where Product_Family_Id = @BIKeyId)
        END
      update Product_Family set Comment_Id = @TopOfChainId
        where Product_Family_Id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 56 --Product Properties
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Product_Properties where Prop_Id = @BIKeyId)
        END
      update Product_Properties set Comment_Id = @TopOfChainId
        where Prop_Id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 57 --Production Plan Starts
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Production_Plan_Starts where PP_Start_Id = @BIKeyId)
        END
      update Production_Plan_Starts set Comment_Id = @TopOfChainId
        where PP_Start_Id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 58 --Report Tree Templates
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Report_Tree_Templates where Report_Tree_Template_Id = @BIKeyId)
        END
      update Report_Tree_Templates set Comment_Id = @TopOfChainId
        where Report_Tree_Template_Id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 59 --Report Webpages
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Report_Webpages where RWP_Id = @BIKeyId)
        END
      update Report_Webpages set Comment_Id = @TopOfChainId
        where RWP_Id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 60 --Saved Queries
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Saved_Queries where Query_Id = @BIKeyId)
        END
      update Saved_Queries set Comment_Id = @TopOfChainId
        where Query_Id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 61 --Sheets
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Sheets where sheet_id = @BIKeyId)
        END
      update Sheets set Comment_Id = @TopOfChainId
        where sheet_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 62 --Shipment
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Shipment where shipment_id = @BIKeyId)
        END
      update Shipment set Comment_Id = @TopOfChainId
        where shipment_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 63 --Shipment Line Items
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Shipment_Line_Items where shipment_item_id = @BIKeyId)
        END
      update Shipment_Line_Items set Comment_Id = @TopOfChainId
        where shipment_item_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 64 --Stored Procs
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Stored_Procs where sp_id = @BIKeyId)
        END
      update Stored_Procs set Comment_Id = @TopOfChainId
        where sp_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 65 --Downtime Summary Action Comment
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Summary_Action_Comment_Id, @TopOfChainId) from Timed_Event_Details where tedet_id = @BIKeyId)
        END
      update Timed_Event_Details set Summary_Action_Comment_Id = @TopOfChainId
        where tedet_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 66 --Downtime Summary Cause Comment
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Summary_Cause_Comment_Id, @TopOfChainId) from Timed_Event_Details where tedet_id = @BIKeyId)
        END
      update Timed_Event_Details set Summary_Cause_Comment_Id = @TopOfChainId
        where tedet_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 67 --Downtime Summary Research Comment
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Summary_Research_Comment_Id, @TopOfChainId) from Timed_Event_Details where tedet_id = @BIKeyId)
        END
      update Timed_Event_Details set Summary_Research_Comment_Id = @TopOfChainId
        where tedet_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 /* Chained not supported
 else if @Table = 68 --Trans Properties
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Trans_Properties 
                  where trans_id = @BIKeyId and Spec_Id = @AddlInfo and Char_Id = @AddlInfo2)
        END
      update Trans_Properties set Comment_Id = @TopOfChainId
        where trans_id = @BIKeyId and Spec_Id = @AddlInfo and Char_Id = @AddlInfo2
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 69 --Trans Variables
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Trans_Variables 
                  where trans_id = @BIKeyId and Var_Id = @AddlInfo and Prod_Id = @AddlInfo2)
        END
      update Trans_Variables set Comment_Id = @TopOfChainId
        where trans_id = @BIKeyId and Var_Id = @AddlInfo and Prod_Id = @AddlInfo2
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 */
 else if @Table = 70 --Transactions
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Transactions where trans_id = @BIKeyId)
        END
      update Transactions set Comment_Id = @TopOfChainId
        where trans_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 71 --Var Specs
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Var_Specs where vs_id = @BIKeyId)
        END
      update Var_Specs set Comment_Id = @TopOfChainId
        where vs_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 72 --Defect Details Action Comment
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Action_Comment_Id, @TopOfChainId) from Defect_Details where Defect_Detail_id = @BIKeyId)
        END
      update Defect_Details set Action_Comment_Id = @TopOfChainId
        where Defect_Detail_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 73 --Defect Details Cause Comment
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Cause_Comment_Id, @TopOfChainId) from Defect_Details where Defect_Detail_id = @BIKeyId)
        END
      update Defect_Details set Cause_Comment_Id = @TopOfChainId
        where Defect_Detail_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 74 --Defect Details Research Comment
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Research_Comment_Id, @TopOfChainId) from Defect_Details where Defect_Detail_id = @BIKeyId)
        END
      update Defect_Details set Research_Comment_Id = @TopOfChainId
        where Defect_Detail_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 75 --PrdExec Paths Comment
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from PrdExec_Paths where Path_id = @BIKeyId)
        END
      update PrdExec_Paths set Comment_Id = @TopOfChainId
        where Path_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 76 --Unit Location Comment
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Unit_Locations where Location_id = @BIKeyId)
        END
      update Unit_Locations set Comment_Id = @TopOfChainId
        where Location_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 77 --Departments Comment
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from Departments where Dept_id = @BIKeyId)
        END
      update Departments set Comment_Id = @TopOfChainId
        where Dept_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
 else if @Table = 78 --PrdExec Path Unit Starts Comment
    begin
      select @TopOfChainId = 
        CASE
          WHEN @Delete = 1 THEN @TopOfChainId
          ELSE (Select Coalesce(Comment_Id, @TopOfChainId) from PrdExec_Path_Unit_Starts where Pepus_id = @BIKeyId)
        END
      update PrdExec_Path_Unit_Starts set Comment_Id = @TopOfChainId
        where Pepus_id = @BIKeyId
      if @@ROWCOUNT = 0 
        begin
          ROLLBACK TRANSACTION
          GOTO Failed
        end
    end
ELSE IF @Table = 79 -- NonProductive_Detail Comment (-- mt added:3-16-2006)
  BEGIN
    SELECT @TopOfChainId =  
      CASE
        WHEN @Delete = 1 THEN @TopOfChainId
        ELSE (Select Coalesce(Comment_Id, @TopOfChainId) FROM NonProductive_Detail WHERE NPDet_Id = @BIKeyId)
      END --CASE
      UPDATE NonProductive_Detail SET Comment_Id = @TopOfChainId WHERE NPDet_Id = @BIKeyId
      If @@ROWCOUNT = 0 
        BEGIN
          ROLLBACK TRANSACTION
          GOTO Failed
        END --If
  END -- (end mt added)
  else if @Table = 99 --ESignature comment
    begin
      select @NewId = @NewId
    end
 ELSE IF @Table = 80 --Activities
    BEGIN
 	  	  	 
 	  	  	 IF @AddlInfo = 'overdue'
            BEGIN
                SELECT @TopOfChainId = CASE
                                           WHEN @Delete = 1
                                           THEN @TopOfChainId
                                           ELSE(SELECT COALESCE(Overdue_Comment_Id, @TopOfChainId) FROM Activities WHERE Activity_Id = @BIKeyId)
                                       END
                UPDATE Activities SET Overdue_Comment_Id = @TopOfChainId WHERE Activity_Id = @BIKeyId
            END 	  	  	 
            ELSE
            BEGIN
                IF @AddlInfo = 'skip'
                    BEGIN
                        SELECT @TopOfChainId = CASE
                                                   WHEN @Delete = 1
                                                   THEN @TopOfChainId
                                                   ELSE(SELECT COALESCE(Skip_Comment_Id, @TopOfChainId) FROM Activities WHERE Activity_Id = @BIKeyId)
                                               END
                        UPDATE Activities SET Skip_Comment_Id = @TopOfChainId WHERE Activity_Id = @BIKeyId
                    END
                    ELSE
 	  	  	  	  	 Begin
 	  	  	  	  	  	 If  @AddlInfo = 'activity_detail'
 	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  SELECT @TopOfChainId = CASE
                                                   WHEN @Delete = 1
                                                   THEN @TopOfChainId
                                                   ELSE(SELECT COALESCE(ActivityDetail_Comment_Id, @TopOfChainId) FROM Activities WHERE Activity_Id = @BIKeyId)
                                               END
 	  	  	  	  	  	  	 UPDATE Activities SET ActivityDetail_Comment_Id = @TopOfChainId WHERE Activity_Id = @BIKeyId
 	  	  	  	  	  	 End
 	  	  	  	  	  	 Else
 	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	 SELECT @TopOfChainId = CASE
 	  	  	  	  	  	  	  	  	  	  	  	  	    WHEN @Delete = 1
 	  	  	  	  	  	  	  	  	  	  	  	  	    THEN @TopOfChainId
 	  	  	  	  	  	  	  	  	  	  	  	  	    ELSE(SELECT COALESCE(Comment_Id, @TopOfChainId) FROM Activities WHERE Activity_Id = @BIKeyId)
 	  	  	  	  	  	  	  	  	  	  	  	    END
 	  	  	  	  	  	  	 UPDATE Activities SET Comment_Id = @TopOfChainId WHERE Activity_Id = @BIKeyId
 	  	  	  	  	  	 End
 	  	  	  	  	 End
            END
        IF @@RowCount = 0
            BEGIN
                ROLLBACK TRANSACTION
                GOTO Failed
            END
    END
ELSE IF @Table In (81,82,83,84,85)
 	 BEGIN
 	 Declare @CommentType nvarchar(50), @EntityType nVarChar(255)
 	 SELECT @EntityType = CASE WHEN @Table = 81 THEN 'WorkOrder' WHEN @Table = 83 Then 'SerialNumber'  END
 	 SELECT @CommentType = @AddlInfo
 	  	  	 select @TopOfChainId = 
 	  	  	  	  	  	 CASE
 	  	  	  	  	  	 WHEN @Delete = 0 THEN @TopOfChainId
 	  	  	  	  	  	 ELSE (Select Coalesce(ThreadId, @TopOfChainId) from Comment_Lookup_Table where EntityId = @BIKeyId)
 	  	  	  	  	  	 END
 	  	  	 IF @CurrentTopOfChainId = 0
 	  	  	 begin
 	  	  	  	 IF @CommentType = 'NONPATYPE'
 	  	  	  	 BEGIN
 	  	  	  	  	 update Comment_Lookup_Table set ThreadId = @TopOfChainId
 	  	  	  	  	 where EntityId= @BIKeyId AND EntityType=@EntityType AND  CommentType =@AddlInfo
 	  	  	  	 END
 	  	  	  	 ELSE
 	  	  	  	 begin
 	  	  	  	  	 update Comment_Lookup_Table set ThreadId = @TopOfChainId
 	  	  	  	  	 where EntityId= @BIKeyId AND EntityType=@EntityType AND  CommentType =@CommentType
 	  	  	  	 END
 	  	  	 END
 	  	  	 else
 	  	  	 begin
 	  	  	  	 SELECT @TopOfChainId = @CurrentTopOfChainId
 	  	  	 end
 	 END
else 
    begin
      ROLLBACK TRANSACTION
      GOTO Failed
    end 
 end
--Set the TopOfChainId and the NextCommentId if necessary
If @Delete = 0 
  begin
    select @PrevCommentId = Max(Comment_Id) from Comments Where TopOfChain_Id = @TopOfChainId
    If @PrevCommentId = @NewId 
      begin
        Select @PrevCommentId = NULL
      end
    update Comments Set TopOfChain_Id = @TopOfChainId Where Comment_Id = @NewId
    update Comments Set NextComment_Id = @NewId Where Comment_Id = @PrevCommentId
  end
Else
    Delete from Comments Where Comment_Id = @CommentId
commit transaction
Select @CurrentTopOfChainId = @TopOfChainId
RETURN
Failed:
Select @NewId = 0 
Select @CurrentTopOfChainId = 0
RETURN
