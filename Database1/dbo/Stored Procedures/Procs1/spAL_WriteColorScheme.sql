Create Procedure dbo.spAL_WriteColorScheme
  @CS_Desc varchar(25),
  @Grid_Lines int,
  @Gray_Area int,
  @Inactive_Area_BG int,
  @Row_Header_BG int,
  @Column_Header_BG int,
  @Read_Only_BG int,
  @Unavailable_BG int,
  @Available_BG int,
  @Ready_BG int,
  @Canceled_BG int,
  @Header_FG int,
  @No_Data_FG int,
  @No_Specification_FG int,
  @Target_FG int,
  @User_FG int,
  @Warning_FG int,
  @Reject_FG int,
  @Entry_FG int AS
  -- Declare local variables.
  DECLARE @CS_Id int
  -- Find our color scheme,
  SELECT @CS_Id = NULL
  SELECT @CS_Id = CS_Id FROM Color_Scheme WHERE CS_Desc = @CS_Desc
  IF @CS_Id IS NULL
    BEGIN
      -- Insert a new color scheme.
      INSERT Color_Scheme(CS_Desc, Grid_Lines, Gray_Area, Inactive_Area_BG, Row_Header_BG,
               Column_Header_BG, Read_Only_BG, Unavailable_BG, Available_BG, Ready_BG,
               Canceled_BG, Header_FG, No_Data_FG, No_Specification_FG, Target_FG,
               User_FG, Warning_FG, Reject_FG, Entry_FG)
        VALUES(@CS_Desc, @Grid_Lines, @Gray_Area, @Inactive_Area_BG, @Row_Header_BG,
               @Column_Header_BG, @Read_Only_BG, @Unavailable_BG, @Available_BG, @Ready_BG,
               @Canceled_BG, @Header_FG, @No_Data_FG, @No_Specification_FG, @Target_FG,
               @User_FG, @Warning_FG, @Reject_FG, @Entry_FG)
      SELECT @CS_Id = Scope_Identity()
      IF @Cs_Id IS NULL RETURN(2)
      RETURN(100)
    END
  ELSE
    BEGIN
      -- Update existing color scheme.
      UPDATE Color_Scheme
        SET Grid_Lines = @Grid_Lines,
            Gray_Area = @Gray_Area,
            Inactive_Area_BG = @Inactive_Area_BG,
            Row_Header_BG = @Row_Header_BG,
            Column_Header_BG = @Column_Header_BG,
            Read_Only_BG = @Read_Only_BG,
            Unavailable_BG = @Unavailable_BG,
            Available_BG = @Available_BG,
            Ready_BG = @Ready_BG,
            Canceled_BG = @Canceled_BG,
            Header_FG = @Header_FG,
            No_Data_FG = @No_Data_FG,
            No_Specification_FG = @No_Specification_FG,
            Target_FG = @Target_FG,
            User_FG = @User_FG,
            Warning_FG = @Warning_FG,
            Reject_FG = @Reject_FG,
            Entry_FG = @Entry_FG
        WHERE CS_Id = @CS_Id
        RETURN(1)
    END
