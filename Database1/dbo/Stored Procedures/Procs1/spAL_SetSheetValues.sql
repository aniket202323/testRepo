Create Procedure dbo.spAL_SetSheetValues
  @Sheet_Desc          nvarchar(50),
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
  @Display_Comment_Win tinyint,
  @Dynamic_Rows        tinyint = 0,
  @Max_Edit_Hours      int = 0,
  @Wrap_Product        tinyint = 0
  AS
  --
  -- Return Code: 100 = Success.
  --
  -- Set sheet values.
  --
  UPDATE Sheets
    SET Master_Unit         = @Master_Unit,
        Event_Prompt        = @Event_Prompt,
        Interval            = @Interval,
        Offset              = @Offset,
        Initial_Count       = @Initial_Count,
        Maximum_Count       = @Maximum_Count,
        Row_Headers         = @Row_Headers,
        Column_Headers      = @Column_Headers,
        Row_Numbering       = @Row_Numbering,
        Column_Numbering    = @Column_Numbering,
        Display_Event       = @Display_Event,
        Display_Date        = @Display_Date,
        Display_Time        = @Display_Time,
        Display_Grade       = @Display_Grade,
        Display_Var_Order   = @Display_Var_Order,
        Display_Data_Type   = @Display_Data_Type,
        Display_Data_Source = @Display_Data_Source,
        Display_Spec        = @Display_Spec,
        Display_Prod_Line   = @Display_Prod_Line,
        Display_Prod_Unit   = @Display_Prod_Unit,
        Display_Description = @Display_Description,
        Display_EngU        = @Display_EngU,
        Group_Id            = @Group_Id,
        Display_Spec_Win    = @Display_Spec_Win,
        Display_Comment_Win = @Display_Comment_Win,
        Dynamic_Rows        = @Dynamic_Rows,
        Max_Edit_Hours      = @Max_Edit_Hours,
        Wrap_Product        = @Wrap_Product
    WHERE Sheet_Desc = @Sheet_Desc
  --
  -- Return success.
  --
  RETURN(100)
