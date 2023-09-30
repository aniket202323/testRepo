Create Procedure dbo.spEMCSC_PutCrewSched
@Delete bit,
@User_Id int,
@PU_Id int,
@Start_Time datetime,
@End_Time datetime,
@Crew_Desc nVarChar(10),
@Shift_Desc nVarChar(10),
@Comment_Id int,
@CS_Id int OUTPUT
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMCSC_PutCrewSched',
             Convert(nVarChar(10),@Delete) + ','  + 
             Convert(nVarChar(10),@User_Id) + ','  + 
             Convert(nVarChar(10),@PU_Id) + ','  + 
             Convert(nvarchar(30),@Start_Time) + ','  + 
             Convert(nvarchar(30),@End_Time) + ','  + 
             @Crew_Desc + ','  + 
             @Shift_Desc + ',' + 
             Convert(nVarChar(10),@Comment_Id) + ','  + 
             Convert(nVarChar(10),@CS_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
If @CS_Id = 0
  Select @CS_Id = NULL
If @Comment_Id = 0
  Select @Comment_Id = NULL
If @Delete = 0
  Begin
    If @CS_Id is NULL and (Select Count(*) From Crew_Schedule Where PU_Id = @PU_Id and Start_Time = @Start_Time and End_Time = @End_Time) > 0
      Begin
        Update Comments Set Comment = '', Comment_Text = '', ShouldDelete = 1 
          Where Comment_Id in (Select Comment_Id From Crew_Schedule Where PU_Id = @PU_Id and Start_Time = @Start_Time and End_Time = @End_Time)
        Select @CS_Id = CS_Id From Crew_Schedule Where PU_Id = @PU_Id and Start_Time = @Start_Time and End_Time = @End_Time
      End
    If @CS_Id is NULL
      Begin
        If (Select Count(*) From Crew_Schedule Where PU_Id = @PU_Id and Start_Time < @Start_Time and End_Time > @End_Time) > 0
          Begin
            Declare @Duplicate_Comment_Id int
            Select @Duplicate_Comment_Id = Comment_Id From Crew_Schedule Where PU_Id = @PU_Id and Start_Time < @Start_Time and End_Time > @End_Time
            If @Duplicate_Comment_Id > 0
              Begin
                Insert Into Comments (Modified_On, User_Id, CS_Id, Comment, Comment_Text)
                  Select dbo.fnServer_CmnGetDate(getUTCdate()), User_Id, CS_Id, Comment, Comment_Text From Comments Where Comment_Id = @Duplicate_Comment_Id
                Select @Duplicate_Comment_Id = Scope_Identity()
              End
            Else
              Select @Duplicate_Comment_Id = NULL
            Insert Into Crew_Schedule (PU_Id, Start_Time, End_Time, Crew_Desc, Shift_Desc, Comment_Id)
              Select PU_Id, @End_Time, End_Time, Crew_Desc, Shift_Desc, @Duplicate_Comment_Id From Crew_Schedule Where PU_Id = @PU_Id and Start_Time < @Start_Time and End_Time > @End_Time
            Update Crew_Schedule Set End_Time = @Start_Time
              Where PU_Id = @PU_Id and Start_Time < @Start_Time and End_Time > @End_Time
          End
        Else
          Begin
            Update Crew_Schedule Set End_Time = @Start_Time,User_Id = @User_Id
              Where PU_Id = @PU_Id and Start_Time < @Start_Time and End_Time >= @Start_Time
            Update Crew_Schedule Set Start_Time = @End_Time,User_Id = @User_Id
              Where PU_Id = @PU_Id and Start_Time <= @End_Time and End_Time > @End_Time
            If (Select Count(*) From Crew_Schedule Where PU_Id = @PU_Id and Start_Time > @Start_Time and End_Time < @End_Time) > 0
              Begin
                Update Comments Set Comment = '', Comment_Text = '', ShouldDelete = 1 
                  Where Comment_Id in (Select Comment_Id From Crew_Schedule Where PU_Id = @PU_Id and ((Start_Time >= @Start_Time and End_Time < @End_Time) or (Start_Time > @Start_Time and End_Time <= @End_Time)))
                Delete From Crew_Schedule
                  Where PU_Id = @PU_Id and ((Start_Time >= @Start_Time and End_Time < @End_Time) or (Start_Time > @Start_Time and End_Time <= @End_Time))
              End
          End
        Insert Into Crew_Schedule (PU_Id, Start_Time, End_Time, Crew_Desc, Shift_Desc, Comment_Id,User_Id)
          Values (@PU_Id, @Start_Time, @End_Time, @Crew_Desc, @Shift_Desc, @Comment_Id,@User_Id)
        Select @CS_Id = Scope_Identity()
      End
    Else If @CS_Id is NOT NULL
      Begin
        Declare @Previous_Start_Time datetime
        Declare @Next_End_Time datetime
        Declare @Previous_CS_Id int
        Declare @Next_CS_Id int
        Select @Previous_Start_Time = Max(Start_Time) From Crew_Schedule Where CS_Id <> @CS_Id and PU_Id = @PU_Id and Start_Time < @Start_Time
        Select @Next_End_Time = Min(End_Time) From Crew_Schedule Where CS_Id <> @CS_Id and PU_Id = @PU_Id and End_Time > @End_Time
        Select @Previous_CS_Id = CS_Id From Crew_Schedule Where PU_Id = @PU_Id and Start_Time = @Previous_Start_Time
        Select @Next_CS_Id = CS_Id From Crew_Schedule Where PU_Id = @PU_Id and End_Time = @Next_End_Time
        Update Crew_Schedule Set End_Time = @Start_Time,User_Id = @User_Id
          Where CS_Id = @Previous_CS_Id
        Update Crew_Schedule Set Start_Time = @End_Time,User_Id = @User_Id
          Where CS_Id = @Next_CS_Id
        Update Comments Set Comment = '', Comment_Text = '', ShouldDelete = 1 
          Where Comment_Id in (Select Comment_Id From Crew_Schedule Where CS_Id <> @CS_Id and PU_Id = @PU_Id and ((Start_Time >= @Start_Time and End_Time < @End_Time) or (Start_Time > @Start_Time and End_Time <= @End_Time)))
        Delete From Crew_Schedule
          Where CS_Id <> @CS_Id and PU_Id = @PU_Id and ((Start_Time >= @Start_Time and End_Time < @End_Time) or (Start_Time > @Start_Time and End_Time <= @End_Time))
        Update Crew_Schedule Set PU_Id = @PU_Id, Start_Time = @Start_Time, End_Time = @End_Time, Crew_Desc = @Crew_Desc, Shift_Desc = @Shift_Desc, Comment_Id = @Comment_Id,User_Id = @User_Id
          Where CS_Id = @CS_Id
      End
  End
Else
  Begin
 	 SELECT @Start_Time = Start_Time,@End_Time = End_Time,@PU_Id =PU_Id,@Comment_Id = Comment_Id
 	   FROM Crew_Schedule c
 	   Where CS_Id = @CS_Id
 	 IF @Comment_Id Is Not Null
 	 BEGIN
 	  	 DELETE FROM Comments Where TopOfChain_Id = @Comment_Id 
 	  	 DELETE FROM Comments Where Comment_Id = @Comment_Id 
 	 END
    Delete From Crew_Schedule
      Where CS_Id = @CS_Id
    Update Crew_Schedule Set End_Time = @End_Time,User_Id = @User_Id
      Where PU_Id = @PU_Id and End_Time = @Start_Time
  End
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
