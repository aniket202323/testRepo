CREATE PROCEDURE dbo.spEM_DupSheet
  @Sheet_Desc        nvarchar(50),
  @Original_Sheet_Id int,
  @User_Id   int,
  @Sheet_Id          int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create sheet.
  --
  -- Declare local variables.
  --
  DECLARE @Event_Type          tinyint,
          @Master_Unit         int,
          @Event_Prompt        nvarchar(25),
          @Interval            Smallint_Offset,
          @Offset              Smallint_Offset,
          @Initial_Count       Int_Natural,
          @Maximum_Count       Int_Natural,
          @Row_Headers         bit,
          @Column_Headers      bit,
          @Row_Numbering       tinyint,
          @Column_Numbering    tinyint,
          @Display_Event       bit,
          @Display_Date        bit,
          @Display_Time        bit,
          @Display_Grade       bit,
          @Display_Var_Order   bit,
          @Display_Data_Type   bit,
          @Display_Data_Source bit,
          @Display_Spec        bit,
          @Display_Prod_Line   bit,
          @Display_Prod_Unit   bit,
          @Display_Description bit,
          @Display_EngU        bit,
          @Group_Id            int,
          @Display_Spec_Win    tinyint,
          @Comment_Id          int,
          @Sheet_Type          tinyint,
          @External_Link       nvarchar(255),
  	   @Dynamic 	        tinyint,
 	   @MaxEditHrs 	        Int,
 	   @WrapProd 	        TinyInt,
 	   @DispComWin 	        TinyInt,
 	   @AutoStatus 	        TinyInt,
 	   @DisplaySpecCol      Bit,
 	   @MaxInvDays 	        Int,
 	   @ProdLine 	        Int,
 	  	 @Grp_Id 	  	  	 Int
  DECLARE @Insert_Id integer,
          @BinId 	 Integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DupSheet',
                 @Sheet_Desc + ','  + Convert(nVarChar(10), @Original_Sheet_Id) + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Begin a transaction
  --
  --
  -- Get original sheet values.
  --
  SELECT @Event_Type          = Event_Type,
         @Master_Unit         = Master_Unit,
         @Event_Prompt        = Event_Prompt,
         @Interval            = Interval,
         @Offset              = Offset,
         @Initial_Count       = Initial_Count,
         @Maximum_Count       = Maximum_Count,
         @Row_Headers         = Row_Headers,
         @Column_Headers      = Column_Headers,
         @Row_Numbering       = Row_Numbering,
         @Column_Numbering    = Column_Numbering,
         @Display_Event       = Display_Event,
         @Display_Date        = Display_Date,
         @Display_Time        = Display_Time,
         @Display_Grade       = Display_Grade,
         @Display_Var_Order   = Display_Var_Order,
         @Display_Data_Type   = Display_Data_Type,
         @Display_Data_Source = Display_Data_Source,
         @Display_Spec        = Display_Spec,
         @Display_Prod_Line   = Display_Prod_Line,
         @Display_Prod_Unit   = Display_Prod_Unit,
         @Display_Description = Display_Description,
         @Display_EngU        = Display_EngU,
         @Group_Id            = Group_Id,
         @Display_Spec_Win    = Display_Spec_Win,
         @Comment_Id          = Comment_Id,
         @Sheet_Type          = Sheet_Type,
         @External_Link       = External_Link,
 	  @Dynamic 	       = Dynamic_Rows,
 	  @MaxEditHrs 	       = Max_Edit_Hours,
 	  @WrapProd 	       = Wrap_Product,
 	  @DispComWin 	       = Display_Comment_Win,
 	  @AutoStatus 	       = Auto_Label_Status,
 	  @DisplaySpecCol      = Display_Spec_Column,
 	  @MaxInvDays 	       = Max_Inventory_Days,
 	  @ProdLine 	       = PL_Id,
 	  @Grp_Id 	  	 = Sheet_Group_Id
 	 FROM Sheets WHERE Sheet_Id = @Original_Sheet_Id
  --
  -- Create new sheet.
  --
  BEGIN TRANSACTION
 	 Execute spEM_CreateSheet @Sheet_Desc,@Sheet_Type, @Event_Type, @Grp_Id, @User_Id,@Sheet_Id OUTPUT
 	 If  @Sheet_Id is not null
 	   Update Sheets Set Master_Unit = @Master_Unit, Event_Prompt = @Event_Prompt, Interval = @Interval, Offset = @Offset,
                     Initial_Count = @Initial_Count, Maximum_Count = @Maximum_Count, Row_Headers = @Row_Headers, 
 	  	  	  	  	  Column_Headers = @Column_Headers, Row_Numbering = @Row_Numbering,
                     Column_Numbering = @Column_Numbering, Display_Event = @Display_Event, Display_Date = @Display_Date, Display_Time = @Display_Time,
 	  	  	  	  	  Display_Grade = @Display_Grade, Display_Var_Order = @Display_Var_Order, Display_Data_Type = @Display_Data_Type, 
 	  	  	  	  	  Display_Data_Source = @Display_Data_Source, Display_Spec = @Display_Spec,Display_Prod_Line = @Display_Prod_Line, 
 	  	  	  	  	  Display_Prod_Unit = @Display_Prod_Unit, Display_Description = @Display_Description, Display_EngU = @Display_EngU,
                     Group_Id = @Group_Id, Display_Spec_Win = @Display_Spec_Win,  Sheet_Type = @Sheet_Type, External_Link = @External_Link,
                     Is_Active = 0, Dynamic_Rows = @Dynamic,Max_Edit_Hours = @MaxEditHrs,Wrap_Product = @WrapProd,Display_Comment_Win = @DispComWin,Auto_Label_Status = @AutoStatus,
 	  	       	  	  Display_Spec_Column = @DisplaySpecCol,Max_Inventory_Days = @MaxInvDays,PL_Id = @ProdLine
   	  Where Sheet_Id =  @Sheet_Id
   Else
    BEGIN
      ROLLBACK TRANSACTION
      UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1
 	  WHERE Audit_Trail_Id = @Insert_Id
      RETURN(1)
    END
  --
  -- Place variables on new sheet.
  --
  INSERT INTO Sheet_Variables (Sheet_Id,Var_Id,Var_Order,Title)
    SELECT Sheet_Id = @Sheet_Id, v.Var_Id, v.Var_Order, v.Title
      FROM Sheet_Variables v
      WHERE v.Sheet_Id = @Original_Sheet_Id
Insert InTo Sheet_Unit (Sheet_Id,PU_Id)
 	 Select Sheet_Id = @Sheet_Id,PU_Id
 	   From Sheet_Unit
 	   Where Sheet_Id = @Original_Sheet_Id
Insert InTo Sheet_Display_Options (Sheet_Id ,Display_Option_Id, Value) 
 	 Select Sheet_Id = @Sheet_Id,Display_Option_Id, Value
 	   From Sheet_Display_Options
 	   Where Sheet_Id = @Original_Sheet_Id and Display_Option_Id <> 5
/* can not duplicate an image
  If  @Sheet_Type = 10
    Begin
 	 Declare @Bin2Id int
 	 Select @Bin2Id = Binary_Id From Sheet_Display_Options Where Sheet_Id = @Original_Sheet_Id and  Display_Option_Id = 5
 	 IF @Bin2Id is not null
 	   Begin
 	  	 EXECUTE spEM_CreatebinaryId  @Sheet_Id,5,@User_Id,@BinId OUTPUT
 	   End
    End
*/
  --
  -- Commit transaction and return success.
  --
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0,Output_Parameters = convert(nVarChar(10),@Sheet_Id)
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
