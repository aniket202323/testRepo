CREATE PROCEDURE dbo.spEM_PutSheetData
    @Sheet_Id 	  	 integer,
    @MasterUnit 	  	 integer,
    @EventPrompt 	 nvarchar(25),
    @Interval 	  	 smallint,
    @Offset 	  	 smallint,
    @InitialCount 	  	 integer,
    @MaxCount 	  	 integer,
    @RowHeaders 	 bit,
    @ColumnHeaders 	 bit,
    @RowNumbering 	 tinyint,
    @ColNumbering 	 tinyint,
    @DisplayEvent 	 bit,
    @DisplayDate 	 bit,
    @DisplayTime 	 bit,
    @DisplayGrade 	 bit,
    @DisplayVarOrder 	 bit,
    @DisplayDataType 	 bit,
    @DisplayDataSource 	 bit,
    @DisplaySpec 	 bit,
    @DisplayProdLine 	 bit,
    @DisplayProdUnit 	 bit,
    @DisplayDesc 	 bit,
    @DisplayEngU 	 bit,
    @DisplayWinSpec 	 tinyint,
    @DynamicRows 	 tinyint,
    @MaxEditHrs 	  	 integer,
    @WrapProduct 	 tinyint,
    @DisplayCmtWin 	 tinyint,
    @Auto_Label_Status  tinyint = Null,
    @DisplaySpecCol 	 bit,
    @MaxInvDays             integer,
    @Prod_Line 	  	 Integer,
    @PEIId   Integer,
 	 @IsDefault 	  	 Tinyint,
 	 @EventSubtypeId 	 Integer,
    @User_Id  	  	 integer
 AS
  DECLARE @Insert_Id integer 
  Declare @Sheet_Type Int
  Select @Sheet_Type = Sheet_Type from sheets Where Sheet_Id = @Sheet_Id
       INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutSheetData',
                Coalesce(Convert(nVarChar(10),@Sheet_Id),'Null') + ','  + 
                Coalesce(Convert(nVarChar(10),@MasterUnit),'Null') + ','  + 
                Coalesce(@EventPrompt,'Null')  + ','  + 
                Coalesce(Convert(nVarChar(10),@Interval),'Null') + ','  + 
                Coalesce(Convert(nVarChar(10),@Offset),'Null') + ','  + 
                Coalesce(Convert(nVarChar(10),@InitialCount),'Null') + ','  + 
                Coalesce(Convert(nVarChar(10),@MaxCount),'Null') + ','  + 
                Coalesce(Convert(nVarChar(10),@RowHeaders),'Null') + ','  + 
                Coalesce(Convert(nVarChar(10),@ColumnHeaders),'Null') + ','  + 
                Coalesce(Convert(nVarChar(10),@RowNumbering),'Null') + ','  + 
                Coalesce(Convert(nVarChar(10),@ColNumbering),'Null') + ','  + 
                Coalesce(Convert(nVarChar(10),@DisplayEvent),'Null') + ','  + 
                Coalesce(Convert(nVarChar(10),@DisplayDate),'Null') + ','  + 
                Coalesce(Convert(nVarChar(10),@DisplayTime),'Null') + ','  + 
                Coalesce(Convert(nVarChar(10),@DisplayGrade),'Null') + ','  + 
                Coalesce(Convert(nVarChar(10),@DisplayVarOrder),'Null') + ','  + 
                Coalesce(Convert(nVarChar(10), @DisplayDataType),'Null') + ','  + 
                Coalesce(Convert(nVarChar(10),@DisplayDataSource),'Null') + ','  + 
                Coalesce(Convert(nVarChar(10),@DisplaySpec),'Null') + ','  + 
                Coalesce(Convert(nVarChar(10),@DisplayProdLine),'Null') + ','  + 
                Coalesce(Convert(nVarChar(10),@DisplayProdUnit),'Null') + ','  + 
                Coalesce(Convert(nVarChar(10),@DisplayDesc),'Null') + ','  + 
                Coalesce(Convert(nVarChar(10),@DisplayEngU),'Null') + ','  + 
                Coalesce(Convert(nVarChar(10),@DisplayWinSpec),'Null') + ','  + 
                Coalesce(Convert(nVarChar(10),@DynamicRows),'Null') + ','  + 
                Coalesce(Convert(nVarChar(10),@MaxEditHrs),'Null') + ','  + 
                Coalesce(Convert(nVarChar(10),@WrapProduct),'Null') + ','  + 
                Coalesce(Convert(nVarChar(10),@DisplayCmtWin),'Null') + ','  + 
                Coalesce(Convert(nVarChar(10),@Auto_Label_Status),'Null') + ','  + 
                Coalesce(Convert(nVarChar(10),@DisplaySpecCol),'Null') + ','  + 
                Coalesce(Convert(nVarChar(10),@MaxInvDays),'Null') + ','  + 
                Coalesce(Convert(nVarChar(10),@Prod_Line),'Null') + ','  + 
                Coalesce(Convert(nVarChar(10),@PEIId),'Null') + ','  + 
                Coalesce(Convert(nVarChar(10),@IsDefault),'Null') + ','  + 
                Coalesce(Convert(nVarChar(10),@EventSubtypeId),'Null') + ','  + 
                Coalesce(Convert(nVarChar(10),@User_Id),'Null'),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  UPDATE Sheets
    SET   Master_Unit =  @MasterUnit,
     	 Event_Prompt = @EventPrompt,
     	 Interval = @Interval,
     	 Offset = @Offset,
 	 Initial_Count = @InitialCount,
 	 Maximum_Count = @MaxCount,
  	 Row_Headers = @RowHeaders,
 	 Column_Headers = @ColumnHeaders,
 	 Row_Numbering = @RowNumbering,
 	 Column_Numbering = @ColNumbering,
 	 Display_Event = @DisplayEvent,
 	 Display_Date = @DisplayDate,
 	 Display_Time = @DisplayTime,
 	 Display_Grade = @DisplayGrade,
 	 Display_Var_Order = @DisplayVarOrder,
 	 Display_Data_Type = @DisplayDataType,
 	 Display_Data_Source = @DisplayDataSource,
 	 Display_Spec = @DisplaySpec,
 	 Display_Prod_Line = @DisplayProdLine,
 	 Display_Prod_Unit = @DisplayProdUnit,
 	 Display_Description = @DisplayDesc,
 	 Display_EngU = @DisplayEngU,
 	 Display_Spec_Win = @DisplayWinSpec,
 	 Dynamic_Rows = @DynamicRows,
 	 Max_Edit_Hours = @MaxEditHrs,
 	 Wrap_Product = @WrapProduct,
 	 Auto_Label_Status = @Auto_Label_Status,
 	 Display_Spec_Column = @DisplaySpecCol,
 	 Display_Comment_Win = @DisplayCmtWin,
 	 Max_Inventory_Days = @MaxInvDays,
 	 PL_Id = @Prod_Line,
   	 PEI_Id = @PEIId,
 	 Event_Subtype_Id = @EventSubtypeId
    WHERE Sheet_Id = @Sheet_Id
  If @Sheet_Type = 2 -- Event based AL
 	   If @IsDefault = 1
 	  	 Begin
 	  	   Update Prod_Units set Def_Event_Sheet_Id = @Sheet_Id Where PU_Id = @MasterUnit
 	  	 End
 	   Else
 	  	 Begin
 	  	   Update Prod_Units set Def_Event_Sheet_Id = null Where PU_Id = @MasterUnit and Def_Event_Sheet_Id = @Sheet_Id
 	  	 End
  If @Sheet_Type = 19 -- event_Component AL
 	   If @IsDefault = 1
 	  	 Begin
 	  	   Update PrdExec_Inputs set Def_Event_Comp_Sheet_Id = @Sheet_Id Where PEI_Id = @PEIId 
 	  	 End
 	   Else
 	  	 Begin
 	  	  	 Update PrdExec_Inputs set Def_Event_Comp_Sheet_Id = Null Where PEI_Id = @PEIId and Def_Event_Comp_Sheet_Id = @Sheet_Id
 	  	 End
  If @Sheet_Type = 30 and @Prod_Line Is Not Null
  BEGIN
 	 DELETE su
 	  	 FROM Sheet_Unit  su
 	  	 Join sheets s on s.Sheet_Id = su.Sheet_Id 
 	  	 Join Prod_Units pu on pu.PU_Id = su.PU_Id
 	  	 Join Prod_Lines pl on pl.PL_Id = pu.PL_Id 
 	  	 WHERE s.Sheet_Type = 30 and su.Sheet_Id <> @Sheet_Id and pu.PL_Id = @Prod_Line
  END  
 UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
