CREATE PROCEDURE dbo.spEM_IEImportDisplayPlots
 	 @Sheet_Desc nvarchar(50),
 	 @SPC_Trend_Type_Desc nvarchar(50),
 	 @Plot_Order tinyint,
  @PL_Desc1 nvarchar(50),
  @PU_Desc1 nvarchar(50),
  @Var_Desc1 nvarchar(50),
  @PL_Desc2 nvarchar(50),
  @PU_Desc2 nvarchar(50),
  @Var_Desc2 nvarchar(50),
  @PL_Desc3 nvarchar(50),
  @PU_Desc3 nvarchar(50),
  @Var_Desc3 nvarchar(50),
  @PL_Desc4 nvarchar(50),
  @PU_Desc4 nvarchar(50),
  @Var_Desc4 nvarchar(50),
  @PL_Desc5 nvarchar(50),
  @PU_Desc5 nvarchar(50),
  @Var_Desc5 nvarchar(50),
 	 @User_Id int
AS
Declare
 	 @Sheet_Id Integer,
 	 @SPC_Trend_Type_Id Integer,
 	 @PL_Id1 Integer,
 	 @PU_Id1 Integer,
 	 @Var_Id1 Integer,
 	 @PL_Id2 Integer,
 	 @PU_Id2 Integer,
 	 @Var_Id2 Integer,
 	 @PL_Id3 Integer,
 	 @PU_Id3 Integer,
 	 @Var_Id3 Integer,
 	 @PL_Id4 Integer,
 	 @PU_Id4 Integer,
 	 @Var_Id4 Integer,
 	 @PL_Id5 Integer,
 	 @PU_Id5 Integer,
 	 @Var_Id5 Integer,
 	 @IsLast Bit,
 	 @IsFirst Bit
Select @Sheet_Id = Null
Select @SPC_Trend_Type_Id = Null
Select @PL_Id1 = Null
Select @PU_Id1 = Null
Select @Var_Id1 = Null
Select @PL_Id2 = Null
Select @PU_Id2 = Null
Select @Var_Id2 = Null
Select @PL_Id3 = Null
Select @PU_Id3 = Null
Select @Var_Id3 = Null
Select @PL_Id4 = Null
Select @PU_Id4 = Null
Select @Var_Id4 = Null
Select @PL_Id5 = Null
Select @PU_Id5 = Null
Select @Var_Id5 = Null
Select @IsLast = 0
Select @IsFirst = 0
------------------------------------------------------------------------------------------
-- Trim Parameters
------------------------------------------------------------------------------------------
Select @Sheet_Desc = LTrim(RTrim(@Sheet_Desc))
Select @SPC_Trend_Type_Desc = LTrim(RTrim(@SPC_Trend_Type_Desc))
Select @PL_Desc1 = LTrim(RTrim(@PL_Desc1))
Select @PU_Desc1 = LTrim(RTrim(@PU_Desc1))
Select @Var_Desc1 = LTrim(RTrim(@Var_Desc1))
Select @PL_Desc2 = LTrim(RTrim(@PL_Desc2))
Select @PU_Desc2 = LTrim(RTrim(@PU_Desc2))
Select @Var_Desc2 = LTrim(RTrim(@Var_Desc2))
Select @PL_Desc3 = LTrim(RTrim(@PL_Desc3))
Select @PU_Desc3 = LTrim(RTrim(@PU_Desc3))
Select @Var_Desc3 = LTrim(RTrim(@Var_Desc3))
Select @PL_Desc4 = LTrim(RTrim(@PL_Desc4))
Select @PU_Desc4 = LTrim(RTrim(@PU_Desc4))
Select @Var_Desc4 = LTrim(RTrim(@Var_Desc4))
Select @PL_Desc5 = LTrim(RTrim(@PL_Desc5))
Select @PU_Desc5 = LTrim(RTrim(@PU_Desc5))
Select @Var_Desc5 = LTrim(RTrim(@Var_Desc5))
-- Verify Arguments 
If @Sheet_Desc = '' or @Sheet_Desc IS NULL
 BEGIN
   Select 'Failed - Sheet Name Missing'
   Return(-100)
 END
If @SPC_Trend_Type_Desc = '' or @SPC_Trend_Type_Desc IS NULL
 BEGIN
   Select 'Failed - Trend Type Missing'
   Return(-100)
 END
If @PL_Desc1 = '' or @PL_Desc1 IS NULL
 BEGIN
   Select 'Failed - Production Line #1 Description Missing'
   Return(-100)
 END
If @PU_Desc1 = '' or @PU_Desc1 IS NULL
 BEGIN
   Select 'Failed - Production Unit #1 Description Missing'
   Return(-100)
 END
If @Var_Desc1 = '' or @Var_Desc1 IS NULL
 BEGIN
   Select 'Failed - Variable #1 Description Missing'
   Return(-100)
 END
------------------------------------------------------------------------------------------
--Insert or Update Display Plots
------------------------------------------------------------------------------------------
Select @Sheet_Id = Sheet_Id 
  from Sheets
  where Sheet_Desc = @Sheet_Desc
If @Sheet_Id IS NULL
 BEGIN
   Select 'Failed - Sheet Name Not Found'
   Return(-100)
 END
Select @SPC_Trend_Type_Id = SPC_Trend_Type_Id 
  from SPC_Trend_Types
  where SPC_Trend_Type_Desc = @SPC_Trend_Type_Desc
If @SPC_Trend_Type_Id IS NULL
 BEGIN
   Select 'Failed - SPC Trend Type Not Found'
   Return(-100)
 END
Select @PL_Id1 = PL_Id 
  from Prod_Lines
  where PL_Desc = @PL_Desc1
If @PL_Id1 IS NULL
 BEGIN
   Select 'Failed - Production Line #1 Not Found'
   Return(-100)
 END
Select @PU_Id1 = PU_Id 
  from Prod_Units
  where PU_Desc = @PU_Desc1
  and PL_Id = @PL_Id1
If @PU_Id1 IS NULL
 BEGIN
   Select 'Failed - Production Unit #1 Not Found'
   Return(-100)
 END
Select @Var_Id1 = Var_Id 
  from Variables
  where Var_Desc = @Var_Desc1
  and PU_Id = @PU_Id1
If @Var_Id1 IS NULL
 BEGIN
   Select 'Failed - Variable #1 Not Found'
   Return(-100)
 END
if @PL_Desc2 <> '' and @PL_Desc2 is NOT NULL
  Begin
    Select @PL_Id2 = PL_Id 
      from Prod_Lines
      where PL_Desc = @PL_Desc2
      If @PL_Id2 IS NULL
       BEGIN
         Select 'Failed - Production Line #2 Not Found'
         Return(-100)
       END
    Select @PU_Id2 = PU_Id 
      from Prod_Units
      where PU_Desc = @PU_Desc2
      and PL_Id = @PL_Id2
    If @PU_Id2 IS NULL
     BEGIN
       Select 'Failed - Production Unit #2 Not Found'
       Return(-100)
     END
    Select @Var_Id2 = Var_Id 
      from Variables
      where Var_Desc = @Var_Desc2
      and PU_Id = @PU_Id2
    If @Var_Id2 IS NULL
     BEGIN
       Select 'Failed - Variable #2 Not Found'
       Return(-100)
     END
    if @PL_Desc3 <> '' and @PL_Desc3 is NOT NULL
      Begin
        Select @PL_Id3 = PL_Id 
          from Prod_Lines
          where PL_Desc = @PL_Desc3
          If @PL_Id3 IS NULL
           BEGIN
             Select 'Failed - Production Line #3 Not Found'
             Return(-100)
           END
        Select @PU_Id3 = PU_Id 
          from Prod_Units
          where PU_Desc = @PU_Desc3
          and PL_Id = @PL_Id3
        If @PU_Id3 IS NULL
         BEGIN
           Select 'Failed - Production Unit #3 Not Found'
           Return(-100)
         END
        Select @Var_Id3 = Var_Id 
          from Variables
          where Var_Desc = @Var_Desc3
          and PU_Id = @PU_Id3
        If @Var_Id3 IS NULL
         BEGIN
           Select 'Failed - Variable #3 Not Found'
           Return(-100)
         END
        if @PL_Desc4 <> '' and @PL_Desc4 is NOT NULL
          Begin
            Select @PL_Id4 = PL_Id 
              from Prod_Lines
              where PL_Desc = @PL_Desc4
            If @PL_Id4 IS NULL
             BEGIN
               Select 'Failed - Production Line #4 Not Found'
               Return(-100)
             END
            Select @PU_Id4 = PU_Id 
              from Prod_Units
              where PU_Desc = @PU_Desc4
              and PL_Id = @PL_Id4
            If @PU_Id4 IS NULL
             BEGIN
               Select 'Failed - Production Unit #4 Not Found'
               Return(-100)
             END
            Select @Var_Id4 = Var_Id 
              from Variables
              where Var_Desc = @Var_Desc4
              and PU_Id = @PU_Id4
            If @Var_Id4 IS NULL
             BEGIN
               Select 'Failed - Variable #4 Not Found'
               Return(-100)
             END
            if @PL_Desc5 <> '' and @PL_Desc5 is NOT NULL
              Begin
                Select @PL_Id5 = PL_Id 
                  from Prod_Lines
                  where PL_Desc = @PL_Desc5
                If @PL_Id5 IS NULL
                 BEGIN
                   Select 'Failed - Production Line #5 Not Found'
                   Return(-100)
                 END
                Select @PU_Id5 = PU_Id 
                  from Prod_Units
                  where PU_Desc = @PU_Desc5
                  and PL_Id = @PL_Id5
                If @PU_Id5 IS NULL
                 BEGIN
                   Select 'Failed - Production Unit #5 Not Found'
                   Return(-100)
                 END
                Select @Var_Id5 = Var_Id 
                  from Variables
                  where Var_Desc = @Var_Desc5
                  and PU_Id = @PU_Id5
                If @Var_Id5 IS NULL
                 BEGIN
                   Select 'Failed - Variable #5 Not Found'
                   Return(-100)
                 END
              End
          End
      End
  End
If (Select Plot_Order From Sheet_Plots Where Sheet_Id = @Sheet_Id and Plot_Order = @Plot_Order) Is Not Null Or @Plot_Order Is Null Or @Plot_Order = 0
Begin
     Select @Plot_Order = Max(Plot_Order)+1
     From Sheet_Plots
     Where Sheet_Id = @Sheet_Id
End
If (Select Count(*) From Sheet_Plots Where Sheet_Id = @Sheet_Id and Var_Id1 = @Var_Id1 and Var_Id2 = @Var_Id2 and Var_Id3 = @Var_Id3 and Var_Id4 = @Var_Id4 and Var_Id5 = @Var_Id5) = 0
  Insert into Sheet_Plots (Sheet_Id,Var_Id1,Var_Id2,Var_Id3,Var_Id4,Var_Id5,SPC_Trend_Type_Id,Plot_Order)
    Values (@Sheet_Id, @Var_Id1, @Var_Id2, @Var_Id3, @Var_Id4, @Var_Id5, @SPC_Trend_Type_Id, @Plot_Order)
Return(0)
