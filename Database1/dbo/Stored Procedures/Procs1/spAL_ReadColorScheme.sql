Create Procedure dbo.spAL_ReadColorScheme
  @CS_Desc nvarchar(25),
  @Grid_Lines int OUTPUT,
  @Gray_Area int OUTPUT,
  @Inactive_Area_BG int OUTPUT,
  @Row_Header_BG int OUTPUT,
  @Column_Header_BG int OUTPUT,
  @Read_Only_BG int OUTPUT,
  @Unavailable_BG int OUTPUT,
  @Available_BG int OUTPUT,
  @Ready_BG int OUTPUT,
  @Canceled_BG int OUTPUT,
  @Header_FG int OUTPUT,
  @No_Data_FG int OUTPUT,
  @No_Specification_FG int OUTPUT,
  @Target_FG int OUTPUT,
  @User_FG int OUTPUT,
  @Warning_FG int OUTPUT,
  @Reject_FG int OUTPUT,
  @Entry_FG int OUTPUT AS
  -- Declare local variables.
  DECLARE @CS_Id int
  -- Find our color scheme,
  SELECT @CS_Id = NULL
  SELECT @CS_Id = CS_Id,
         @Grid_Lines = Grid_Lines,
         @Gray_Area = Gray_Area,
         @Inactive_Area_BG = Inactive_Area_BG,
         @Row_Header_BG = Row_Header_BG,
         @Column_Header_BG = Column_Header_BG,
         @Read_Only_BG = Read_Only_BG,
         @Unavailable_BG = Unavailable_BG,
         @Available_BG = Available_BG,
         @Ready_BG = Ready_BG,
         @Canceled_BG = Canceled_BG,
         @Header_FG = Header_FG,
         @No_Data_FG = No_Data_FG,
         @No_Specification_FG = No_Specification_FG,
         @Target_FG = Target_FG,
         @User_FG = User_FG,
         @Warning_FG = Warning_FG,
         @Reject_FG = Reject_FG,
         @Entry_FG = Entry_FG
    FROM Color_Scheme WHERE CS_Desc = @CS_Desc
  IF @CS_Id IS NULL RETURN(1)
  RETURN(100)
