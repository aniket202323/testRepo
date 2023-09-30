   /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-30  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
     Remove 1 temp table  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Stored Procedure: spLocal_GetPOCSummaryData  
Author:   Matt Wells (MSI)  
Date Created:  05/30/02  
  
Description:  
=========  
This procedure provides Process Order Confirmation data for a given Line and Time Period.  
  
  
INPUTS: Start Time  
  End Time  
  Production Line Name (without the TT prefix)  
  Product ID for Report 0:  Returns summary data grouped by Product for all Products run in time period specified  
     Product ID: Returns summary data for this Product ID in time period specified  
  
CALLED BY:  POCSummary.xlt (Excel/VBA Template)  
  
CALLS: None  
  
Revision Change Date Who What  
======== =========== ==== =====  
0.0  5/30/02  MKW Original Creation  
*/  
CREATE PROCEDURE dbo.spLocal_GetPOCSummaryData  
--Declare  
  
@Report_Start_Time datetime,  
@Report_End_Time datetime,  
@Line_Name   varchar(50),  
@Report_Prod_Id int  
AS  
  
Declare @Time1 datetime, @Time2 datetime, @Time3 datetime, @Time4 datetime, @Time5 datetime  
/* Testing...   
Select  @PL_Id    = 2,  
 @Report_Start_Time  = '2002-03-01 00:00:00',  
 @Report_End_Time    = '2002-03-31 00:00:00',  
  @Data_Category  = 'Production', --'SheetBreaks' --'Quality' --   
 @Report_Prod_Id  = Null --1013  
  
  
--select @PL_Id,@Report_Start_Time,@Report_End_Time,@Data_Category  
  
--execute spLocal_GetDDSSummaryData '2002-01-02 00:00:00', '2002-01-02 00:00:00', 5, 'ggg'  
*/   
  
/************************************************************************************************  
*                                                                                               *  
*                                 Global execution switches                                     *  
*                                                                                               *  
************************************************************************************************/  
SET NOCOUNT ON  
SET ANSI_WARNINGS OFF  
  
  
/************************************************************************************************  
*                                                                                               *  
*                                        Declarations                                           *  
*                                                                                               *  
************************************************************************************************/  
-- Create Table #Production_Runs (  
--  Start_Id int Primary Key,  
--  Prod_Id  int Not Null,  
--  Prod_Desc varchar(50),  
--  Start_Time datetime Not Null,  
--  End_Time datetime Not Null  
-- )  
  
DECLARE @Summary_Data TABLE(  
 Plant    varchar(25),  
 Storage_Location  varchar(25),  
 Product    varchar(50),  
 Product_Time   decimal(15,2),  
 GCAS    varchar(25),  
 Reel_Tons   decimal(15,2),  
 Furnish    decimal(15,2),  
 Third_Furnish   decimal(15,2),  
 Absorb_Aid_Towel  decimal(15,2),  
 Air    decimal(15,2),  
 Biocide    decimal(15,2),  
 Cat_Promoter   decimal(15,2),  
 Chem_1    decimal(15,2),  
 Chem_2    decimal(15,2),  
 Chlorine_Control   decimal(15,2),  
 CTMP    decimal(15,2),  
 Defoamer   decimal(15,2),  
 Dry_Strength_Tissue  decimal(15,2),  
 Dry_Strength_Towel  decimal(15,2),  
 Dye_1    decimal(15,2),  
 Dye_2    decimal(15,2),  
 Electric    decimal(15,2),  
 Emulsion_1   decimal(15,2),  
 Emulsion_2   decimal(15,2),  
 Fiber_1    decimal(15,2),  
 Fiber_2    decimal(15,2),  
 Flocculant   decimal(15,2),  
 Gas    decimal(15,2),  
 Glue_Adhesive   decimal(15,2),  
 Glue_Crepe_Aid   decimal(15,2),  
 Glue_Release_Aid  decimal(15,2),  
 Glue_Total   decimal(15,2),  
 Long_Fiber   decimal(15,2),  
-- Machine_Broke   decimal(15,2),  
 pH_Control_Tissue_Acid  decimal(15,2),  
 pH_Control_Towel_Base  decimal(15,2),  
 Product_Broke   decimal(15,2),  
 Short_Fiber   decimal(15,2),  
 Single_Glue   decimal(15,2),  
 Softener_Tissue   decimal(15,2),  
 Softener_Towel   decimal(15,2),  
 Steam    decimal(15,2),  
 Water    decimal(15,2),  
 Wet_Strength_Tissue  decimal(15,2),  
 Wet_Strength_Towel  decimal(15,2)  
)  
  
Declare @PL_Id     int,  
-- @Line_Name    varchar(50),  
 @Result    varchar(25),  
 @Total     real,  
 @Count     int,  
 @TNE_Conversion   real,  
 @KG_Conversion   real,  
 @LB_Conversion   real,  
 @Production_PU_Id   int,  
 @Quality_PU_Id    int,  
 @Rolls_PU_Id    int,  
 @Sheetbreak_PU_Id   int,  
 @Materials_PU_Id   int,  
 @Reel_Time_Var_Id   int,  
 @Product_Start_Time   datetime,  
 @Product_End_Time   datetime,  
 @Prod_Id    int,  
 @Prod_Desc    varchar(50),  
 @Last_Prod_Id    int,  
 @Last_Prod_Desc   varchar(50),  
 @Product_Time    real,  
 @Prop_Id    int,  
 @Ratio_Spec_Id    int,  
 @GCAS_Char_Id    int,  
 @GCAS     varchar(8),  
 @Last_GCAS    varchar(8),  
 @Ratio     real,  
             --**************** Tonnage/Count Variables ***************  
 @Roll_Tons_Var_Id   int,  
 @Reel_Tons_Sum   real,  
 @Slab_Var_Id    int,  
 @Teardown_Var_Id   int,  
 @Valid_Tons_Limit   real,  
             --**************** Plant/Location Variables ***************  
 @Extended_Info    varchar(255),  
 @Plant     varchar(25),  
 @Plant_Flag    varchar(25),  
 @Storage_Location   varchar(25),  
 @Storage_Location_Flag   varchar(25),  
 @Flag_Start_Position   int,  
 @Flag_End_Position   int,  
 @Flag_Value_Str    varchar(255),  
             --************** Furnish Variables ***************  
 @3rd_Furnish_Var_Id   int,  
 @CTMP_Var_Id    int,  
 @Fiber_1_Var_Id   int,  
 @Fiber_2_Var_Id   int,  
 @Long_Fiber_Var_Id   int,  
 @Machine_Broke_Var_Id  int,  
 @Product_Broke_Var_Id   int,  
 @Short_Fiber_Var_Id   int,  
 @3rd_Furnish_Sum   float,  
 @CTMP_Sum    float,  
 @Fiber_1_Sum    float,  
 @Fiber_2_Sum    float,  
 @Long_Fiber_Sum   float,  
 @Machine_Broke_Sum   float,  
 @Product_Broke_Sum   float,  
 @Short_Fiber_Sum   float,  
 @Furnish_Sum    float,  
             --************** Chemical Variables ***************  
 @Absorb_Aid_Towel_Var_Id  int,  
 @Biocide_Var_Id   int,  
 @Cat_Promoter_Var_Id   int,  
 @Chem_1_Var_Id   int,  
 @Chem_2_Var_Id   int,  
 @Chlorine_Control_Var_Id  int,  
 @Defoamer_Var_Id   int,  
 @Dry_Strength_Tissue_Var_Id  int,  
 @Dry_Strength_Towel_Var_Id  int,  
 @Dye_1_Var_Id    int,  
 @Dye_2_Var_Id    int,  
 @Emulsion_1_Var_Id   int,  
 @Emulsion_2_Var_Id   int,  
 @Flocculant_Var_Id   int,  
 @Glue_Adhesive_Var_Id  int,  
 @Glue_Crepe_Aid_Var_Id  int,  
 @Glue_Release_Aid_Var_Id  int,  
 @Glue_Total_Var_Id   int,  
 @pH_Control_Tissue_Acid_Var_Id int,  
 @pH_Control_Towel_Base_Var_Id int,  
 @Single_Glue_Var_Id   int,  
 @Softener_Tissue_Var_Id  int,  
 @Softener_Towel_Var_Id  int,  
 @Wet_Strength_Tissue_Var_Id  int,  
 @Wet_Strength_Towel_Var_Id  int,  
 @Absorb_Aid_Towel_Sum  float,  
 @Biocide_Sum    float,  
 @Cat_Promoter_Sum   float,  
 @Chem_1_Sum    float,  
 @Chem_2_Sum    float,  
 @Chlorine_Control_Sum   float,  
 @Defoamer_Sum   float,  
 @Dry_Strength_Tissue_Sum  float,  
 @Dry_Strength_Towel_Sum  float,  
 @Dye_1_Sum    float,  
 @Dye_2_Sum    float,  
 @Emulsion_1_Sum   float,  
 @Emulsion_2_Sum   float,  
 @Flocculant_Sum   float,  
 @Glue_Adhesive_Sum   float,  
 @Glue_Crepe_Aid_Sum   float,  
 @Glue_Release_Aid_Sum  float,  
 @Glue_Total_Sum   float,  
 @pH_Control_Tissue_Acid_Sum  float,  
 @pH_Control_Towel_Base_Sum  float,  
 @Single_Glue_Sum   float,  
 @Softener_Tissue_Sum   float,  
 @Softener_Towel_Sum   float,  
 @Wet_Strength_Tissue_Sum  float,  
 @Wet_Strength_Towel_Sum  float,  
             --**************** Utility Variables *****************  
 @Air_Var_Id    int,  
 @Electric_Var_Id   int,  
 @Gas_Var_Id    int,  
 @Steam_Var_Id    int,  
 @Water_Var_Id    int,  
 @Air_Sum    float,  
 @Electric_Sum    float,  
 @Gas_Sum    float,  
 @Steam_Sum    float,  
 @Water_Sum    float  
  
Select @Time1 = getdate()  
  
/************************************************************************************************  
*                                                                                                                               *  
*                                     Initialization                                                               *  
*                                                                                                                               *  
************************************************************************************************/  
Select  @Valid_Tons_Limit   = 0.0,  
 @TNE_Conversion   = 1.102311,  
 @KG_Conversion   = 2.2046,  
 @LB_Conversion   = 2000,  
 @Plant_Flag   = 'Plant=',  
 @Storage_Location_Flag  = 'StorageLocation=',  
 @Product_Time    = Null,  
 @Reel_Tons_Sum    = Null,  
 @Furnish_Sum   = Null,  
 @3rd_Furnish_Sum    = Null,  
 @Absorb_Aid_Towel_Sum   = Null,  
 @Biocide_Sum     = Null,  
 @Cat_Promoter_Sum    = Null,  
 @Chem_1_Sum    = Null,  
 @Chem_2_Sum    = Null,  
 @Chlorine_Control_Sum    = Null,  
 @CTMP_Sum     = Null,  
 @Defoamer_Sum    = Null,  
 @Dry_Strength_Tissue_Sum  = Null,  
 @Dry_Strength_Towel_Sum   = Null,  
 @Dye_1_Sum     = Null,  
 @Dye_2_Sum     = Null,  
 @Emulsion_1_Sum    = Null,  
 @Emulsion_2_Sum    = Null,  
 @Fiber_1_Sum     = Null,  
 @Fiber_2_Sum     = Null,  
 @Flocculant_Sum    = Null,  
 @Glue_Adhesive_Sum    = Null,  
 @Glue_Crepe_Aid_Sum    = Null,  
 @Glue_Release_Aid_Sum   = Null,  
 @Glue_Total_Sum    = Null,  
 @Long_Fiber_Sum    = Null,  
 @Machine_Broke_Sum    = Null,  
 @pH_Control_Tissue_Acid_Sum   = Null,  
 @pH_Control_Towel_Base_Sum   = Null,  
 @Product_Broke_Sum    = Null,  
 @Short_Fiber_Sum    = Null,  
 @Single_Glue_Sum    = Null,  
 @Softener_Tissue_Sum   = Null,  
 @Softener_Towel_Sum   = Null,  
 @Wet_Strength_Tissue_Sum  = Null,  
 @Wet_Strength_Towel_Sum  = Null,  
 @Air_Sum    = Null,  
 @Electric_Sum    = Null,  
 @Gas_Sum    = Null,  
 @Steam_Sum    = Null,  
 @Water_Sum    = Null  
  
  
/************************************************************************************************  
*                                                                                                                               *  
*                                     Get Configuration                                                               *  
*                                                                                                                               *  
************************************************************************************************/  
/* Get the line id */  
Select @PL_Id = PL_Id  
From [dbo].Prod_Lines  
Where PL_Desc = 'TT ' + ltrim(rtrim(@Line_Name))  
--Select @Line_Name = right(PL_Desc, len(PL_Desc)-3)  
--From Prod_Lines  
--Where PL_Id = @PL_Id  
  
/* Get the plant and storage location from the Extended_Info field */  
Select @Extended_Info = Extended_Info  
From [dbo].Prod_Lines  
Where PL_Id = @PL_Id  
  
Select @Flag_Start_Position = charindex(@Plant_Flag, upper(@Extended_Info), 0)  
If @Flag_Start_Position > 0  
     Begin  
     Select @Plant = right(@Extended_Info, len(@Extended_Info)-@Flag_Start_Position-len(@Plant_Flag)+1)  
     Select @Flag_End_Position = charindex(';', @Plant)  
     If @Flag_End_Position > 0  
          Select @Plant = left(@Plant, @Flag_End_Position-1)  
     End  
  
Select @Flag_Start_Position = charindex(@Storage_Location_Flag, upper(@Extended_Info), 0)  
If @Flag_Start_Position > 0  
     Begin  
     Select @Storage_Location = right(@Extended_Info, len(@Extended_Info)-@Flag_Start_Position-len(@Storage_Location_Flag)+1)  
     Select @Flag_End_Position = charindex(';', @Storage_Location)  
     If @Flag_End_Position > 0  
          Select @Storage_Location = left(@Storage_Location, @Flag_End_Position-1)  
     End  
  
/* Get Different PU Ids */  
Select @Production_PU_Id = PU_Id  
From [dbo].Prod_Units  
Where PL_Id = @PL_Id And PU_Desc = @Line_Name + ' Production'  
  
Select @Rolls_PU_Id = PU_Id  
From [dbo].Prod_Units  
Where PL_Id = @PL_Id And PU_Desc = @Line_Name + ' Rolls'  
  
Select @Materials_PU_Id = PU_Id  
From [dbo].Prod_Units  
Where PL_Id = @PL_Id And PU_Desc = @Line_Name + ' Materials'  
  
/* Get tonnage variables */  
Select @Roll_Tons_Var_Id = Var_Id  
From [dbo].Variables  
Where Var_Desc = 'Roll Weight Official' And PU_Id = @Rolls_PU_Id  
  
Select @Slab_Var_Id = Var_Id  
From [dbo].Variables  
Where Var_Desc = 'Roll Slab Weight' And PU_Id = @Rolls_PU_Id  
  
Select @Teardown_Var_Id = Var_Id  
From [dbo].Variables  
Where Var_Desc = 'Roll Teardown Weight' And PU_Id = @Rolls_PU_Id  
  
/* Get property for GCAS configuration */  
Select @Prop_Id = Prop_Id  
From [dbo].Product_Properties  
Where Prop_Desc = 'Pmkg Parent Rolls'  
  
Select @Ratio_Spec_Id = Spec_Id  
From [dbo].Specifications  
Where Prop_Id = @Prop_Id And Spec_Desc = 'Roll Ratio'  
  
/* Get chemical variables */  
Select @3rd_Furnish_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = '3rd Furnish Dry Flow Hr Sum'  
Select @CTMP_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'CTMP Dry Flow Hr Sum'  
Select @Fiber_1_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'Fiber 1 Dry Flow Hr Sum'  
Select @Fiber_2_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'Fiber 2 Dry Flow Hr Sum'  
Select @Long_Fiber_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'Long Fiber Dry Flow Hr Sum'  
Select @Machine_Broke_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'Machine Broke Dry Flow Hr Sum'  
Select @Product_Broke_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'Product Broke Dry Flow Hr Sum'  
Select @Short_Fiber_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'Short Fiber Dry Flow Hr Sum'  
Select @Absorb_Aid_Towel_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'Absorb Aid Towel Mass Flow Hr Sum'  
Select @Biocide_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'Biocide Mass Flow Hr Sum'  
Select @Cat_Promoter_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'Cat Promoter Mass Flow Hr Sum'  
Select @Chem_1_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'Chem 1 Mass Flow Hr Sum'  
Select @Chem_2_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'Chem 2 Mass Flow Hr Sum'  
Select @Chlorine_Control_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'Chlorine Control Mass Flow Hr Sum'  
Select @Defoamer_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'Defoamer Mass Flow Hr Sum'  
Select @Dry_Strength_Tissue_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'Dry Strength Tissue Mass Flow Hr Sum'  
Select @Dry_Strength_Towel_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'Dry Strength Towel Mass Flow Hr Sum'  
Select @Dye_1_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'Dye 1 Mass Flow Hr Sum'  
Select @Dye_2_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'Dye 2 Mass Flow Hr Sum'  
Select @Emulsion_1_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'Emulsion 1 Mass Flow Hr Sum'  
Select @Emulsion_2_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'Emulsion 2 Mass Flow Hr Sum'  
Select @Flocculant_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'Flocculant Mass Flow Hr Sum'  
Select @Glue_Adhesive_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'Glue Adhesive Mass Flow Hr Sum'  
Select @Glue_Crepe_Aid_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'Glue Crepe Aid Mass Flow Hr Sum'  
Select @Glue_Release_Aid_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'Glue Release Aid Mass Flow Hr Sum'  
Select @Glue_Total_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'Glue Total Mass Flow Hr Sum'  
Select @pH_Control_Tissue_Acid_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'pH Control Tissue Acid Mass Flow Hr Sum'  
Select @pH_Control_Towel_Base_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'pH Control Towel Base Mass Flow Hr Sum'  
Select @Single_Glue_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'Single Glue Mass Flow Hr Sum'  
Select @Softener_Tissue_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'Softener Tissue Mass Flow Hr Sum'  
Select @Softener_Towel_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'Softener Towel Mass Flow Hr Sum'  
Select @Wet_Strength_Tissue_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'Wet Strength Tissue Mass Flow Hr Sum'  
Select @Wet_Strength_Towel_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'Wet Strength Towel Mass Flow Hr Sum'  
  
/* Get utility variables */  
Select @Air_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'Turbine Air Mass Flow Hr Sum'  
Select @Electric_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'Electrical Usage Hr Sum'  
Select @Gas_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'Gas Usage Hr Sum'  
Select @Steam_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'Steam Usage Hr Sum'  
Select @Water_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id And Var_Desc = 'Water Usage Hr Sum'  
  
/************************************************************************************************  
*                                                                                                                               *  
*                                     Get Production Statistics                                                   *  
*                                                                                                                               *  
************************************************************************************************/  
/* Open cursor for product runs */  
If @Report_Prod_Id Is Not Null And @Report_Prod_Id > 0  
     Declare ProductRuns Cursor Scroll For  
     Select  ps.Prod_Id,   
  p.Prod_Desc,  
  c.Char_Id,  
  left(c.Char_Desc, 8) As GCAS,  
  Case  When @Report_Start_Time > ps.Start_Time Then @Report_Start_Time  
   Else ps.Start_Time  
   End As Start_Time,   
  Case  When @Report_End_Time < ps.End_Time Or ps.End_Time Is Null Then @Report_End_Time  
   Else ps.End_Time  
   End As End_Time  
     From Production_Starts ps  
          Inner Join Products p On ps.Prod_Id = p.Prod_Id  
          Inner Join Characteristic_Groups cg On p.Prod_Code = cg.Characteristic_Grp_Desc And Prop_Id = @Prop_Id  
          Inner Join Characteristic_Group_Data cgd On cg.Characteristic_Grp_Id = cgd.Characteristic_Grp_Id  
          Inner Join Characteristics c On cgd.Char_Id = c.Char_Id  
     Where PU_Id = @Production_PU_Id And ps.Prod_Id = @Report_Prod_Id And  
                ps.Start_Time < @Report_End_Time And (ps.End_Time > @Report_Start_Time Or ps.End_Time Is Null)  
     Order By p.Prod_Desc Asc, GCAS Asc, Start_Time Asc  
     For Read Only  
Else  
     Declare ProductRuns Cursor Scroll For  
     Select  ps.Prod_Id,   
  p.Prod_Desc,  
  c.Char_Id,  
  left(c.Char_Desc, 8) As GCAS,  
  Case  When @Report_Start_Time > ps.Start_Time Then @Report_Start_Time  
   Else ps.Start_Time  
   End As Start_Time,   
  Case  When @Report_End_Time < ps.End_Time Or ps.End_Time Is Null Then @Report_End_Time  
   Else ps.End_Time  
   End As End_Time  
     From Production_Starts ps  
          Inner Join Products p On ps.Prod_Id = p.Prod_Id  
          Inner Join Characteristic_Groups cg On p.Prod_Code = cg.Characteristic_Grp_Desc And Prop_Id = @Prop_Id  
          Inner Join Characteristic_Group_Data cgd On cg.Characteristic_Grp_Id = cgd.Characteristic_Grp_Id  
          Inner Join Characteristics c On cgd.Char_Id = c.Char_Id  
     Where PU_Id = @Production_PU_Id And  
                ps.Start_Time < @Report_End_Time And (ps.End_Time > @Report_Start_Time Or ps.End_Time Is Null)  
     Order By p.Prod_Desc Asc, GCAS Asc, Start_Time Asc  
     For Read Only  
  
Open ProductRuns  
  
Select @Time2 = getdate()  
  
     Fetch First From ProductRuns Into @Prod_Id, @Prod_Desc, @GCAS_Char_Id, @GCAS, @Product_Start_Time, @Product_End_Time  
     Select  @Last_Prod_Id   = @Prod_Id,  
  @Last_GCAS  = @GCAS,  
  @Last_Prod_Desc = @Prod_Desc  
  
     While @@FETCH_STATUS = 0  
          Begin  
          /* Product Time */  
          Select @Product_Time = IsNull(@Product_Time, 0) + convert(real, datediff(s, @Product_Start_Time, @Product_End_Time))/60  
  
          /* Get Ratio */  
          Select @Ratio = convert(real, Target)/100  
          From Active_Specs asp  
          Where Char_Id = @GCAS_Char_Id And Spec_Id = @Ratio_Spec_Id And  
                Effective_Date <= @Product_Start_Time And (Expiration_Date > @Product_Start_Time Or Expiration_Date Is Null)  
  
          /************************************************************************************************  
          *                                        Production Tonnage/Counts                                          *  
          ************************************************************************************************/  
          /* Roll Tons */  
          Select @Count  = count(Event_Id)  
          From Events  
          Where PU_Id = @Rolls_PU_Id And TimeStamp > @Product_Start_Time And TimeStamp <= @Product_End_Time  
  
          Select @Total = sum(cast(Result As real)) * @Ratio  
          From tests   
          Where Var_Id = @Roll_Tons_Var_Id and Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Result Is Not Null And cast(Result As real) > 0.0  
  
          If @Count > 0  
               Select @Reel_Tons_Sum  = isnull(@Reel_Tons_Sum, 0) + isnull(@Total, 0)  
  
          /* Slab Weight */  
          Select @Total = sum(cast(Result As real)) * @Ratio,  
  @Count = count(Result)  
          From tests   
          Where Var_Id = @Slab_Var_Id and Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Result Is Not Null And cast(Result As real) > 0.0  
  
          If @Count > 0  
               Select @Reel_Tons_Sum  = isnull(@Reel_Tons_Sum, 0) + isnull(@Total, 0)  
  
          /* Teardown Weight */  
          Select @Total = sum(cast(Result As real)) * @Ratio,  
  @Count = count(Result)  
          From tests   
          Where Var_Id = @Teardown_Var_Id and Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Result Is Not Null And cast(Result As real) > 0.0  
  
          If @Count > 0  
               Select @Reel_Tons_Sum  = isnull(@Reel_Tons_Sum, 0) + isnull(@Total, 0)  
  
          /************************************************************************************************  
          *                                           Materials                                           *  
          ************************************************************************************************/  
          /* Furnishes */  
          If @3rd_Furnish_Var_Id Is Not Null  
               Select @3rd_Furnish_Sum = IsNull(@3rd_Furnish_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @3rd_Furnish_Var_Id  
          If @CTMP_Var_Id Is Not Null  
               Select @CTMP_Sum = IsNull(@CTMP_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @CTMP_Var_Id  
          If @Fiber_1_Var_Id Is Not Null  
               Select @Fiber_1_Sum = IsNull(@Fiber_1_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Fiber_1_Var_Id  
          If @Fiber_2_Var_Id Is Not Null  
               Select @Fiber_2_Sum = IsNull(@Fiber_2_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Fiber_2_Var_Id  
          If @Long_Fiber_Var_Id Is Not Null  
               Select @Long_Fiber_Sum = IsNull(@Long_Fiber_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Long_Fiber_Var_Id  
          If @Short_Fiber_Var_Id Is Not Null  
               Select @Short_Fiber_Sum = IsNull(@Short_Fiber_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Short_Fiber_Var_Id  
  
          /* Chemicals */  
          If @Absorb_Aid_Towel_Var_Id Is Not Null  
               Select @Absorb_Aid_Towel_Sum = IsNull(@Absorb_Aid_Towel_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Absorb_Aid_Towel_Var_Id  
          If @Biocide_Var_Id Is Not Null  
               Select @Biocide_Sum = IsNull(@Biocide_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Biocide_Var_Id  
          If @Cat_Promoter_Var_Id Is Not Null  
               Select @Cat_Promoter_Sum = IsNull(@Cat_Promoter_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Cat_Promoter_Var_Id  
          If @Chem_1_Var_Id Is Not Null  
               Select @Chem_1_Sum = IsNull(@Chem_1_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Chem_1_Var_Id  
          If @Chem_2_Var_Id Is Not Null  
               Select @Chem_2_Sum = IsNull(@Chem_2_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Chem_2_Var_Id  
          If @Chlorine_Control_Var_Id Is Not Null  
               Select @Chlorine_Control_Sum = IsNull(@Chlorine_Control_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Chlorine_Control_Var_Id  
          If @Defoamer_Var_Id Is Not Null  
               Select @Defoamer_Sum = IsNull(@Defoamer_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Defoamer_Var_Id  
          If @Dry_Strength_Tissue_Var_Id Is Not Null  
               Select @Dry_Strength_Tissue_Sum = IsNull(@Dry_Strength_Tissue_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Dry_Strength_Tissue_Var_Id  
          If @Dry_Strength_Towel_Var_Id Is Not Null  
               Select @Dry_Strength_Towel_Sum = IsNull(@Dry_Strength_Towel_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Dry_Strength_Towel_Var_Id
  
          If @Dye_1_Var_Id Is Not Null  
               Select @Dye_1_Sum = IsNull(@Dye_1_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Dye_1_Var_Id  
          If @Dye_2_Var_Id Is Not Null  
               Select @Dye_2_Sum = IsNull(@Dye_2_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Dye_2_Var_Id  
          If @Emulsion_1_Var_Id Is Not Null  
               Select @Emulsion_1_Sum = IsNull(@Emulsion_1_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Emulsion_1_Var_Id  
          If @Emulsion_2_Var_Id Is Not Null  
               Select @Emulsion_2_Sum = IsNull(@Emulsion_2_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Emulsion_2_Var_Id  
          If @Flocculant_Var_Id Is Not Null  
               Select @Flocculant_Sum = IsNull(@Flocculant_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Flocculant_Var_Id  
          If @Glue_Adhesive_Var_Id Is Not Null  
               Select @Glue_Adhesive_Sum = IsNull(@Glue_Adhesive_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Glue_Adhesive_Var_Id  
          If @Glue_Crepe_Aid_Var_Id Is Not Null  
               Select @Glue_Crepe_Aid_Sum = IsNull(@Glue_Crepe_Aid_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Glue_Crepe_Aid_Var_Id  
          If @Glue_Release_Aid_Var_Id Is Not Null  
               Select @Glue_Release_Aid_Sum = IsNull(@Glue_Release_Aid_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Glue_Release_Aid_Var_Id  
          If @Glue_Total_Var_Id Is Not Null  
               Select @Glue_Total_Sum = IsNull(@Glue_Total_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Glue_Total_Var_Id  
          If @Machine_Broke_Var_Id Is Not Null  
               Select @Machine_Broke_Sum = IsNull(@Machine_Broke_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Machine_Broke_Var_Id  
          If @pH_Control_Tissue_Acid_Var_Id Is Not Null  
               Select @pH_Control_Tissue_Acid_Sum = IsNull(@pH_Control_Tissue_Acid_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @pH_Control_Tissue_Acid_Var_Id  
          If @pH_Control_Towel_Base_Var_Id Is Not Null  
               Select @pH_Control_Towel_Base_Sum = IsNull(@pH_Control_Towel_Base_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @pH_Control_Towel_Base_Var_Id  
          If @Product_Broke_Var_Id Is Not Null  
               Select @Product_Broke_Sum = IsNull(@Product_Broke_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Product_Broke_Var_Id  
          If @Single_Glue_Var_Id Is Not Null  
               Select @Single_Glue_Sum = IsNull(@Single_Glue_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Single_Glue_Var_Id  
          If @Softener_Tissue_Var_Id Is Not Null  
               Select @Softener_Tissue_Sum = IsNull(@Softener_Tissue_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Softener_Tissue_Var_Id  
          If @Softener_Towel_Var_Id Is Not Null  
               Select @Softener_Towel_Sum = IsNull(@Softener_Towel_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Softener_Towel_Var_Id  
          If @Wet_Strength_Tissue_Var_Id Is Not Null  
               Select @Wet_Strength_Tissue_Sum = IsNull(@Wet_Strength_Tissue_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Wet_Strength_Tissue_Var_Id  
          If @Wet_Strength_Towel_Var_Id Is Not Null  
               Select @Wet_Strength_Towel_Sum = IsNull(@Wet_Strength_Towel_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Wet_Strength_Towel_Var_Id
  
  
          /* Utilities */  
          If @Air_Var_Id Is Not Null  
               Select @Air_Sum = IsNull(@Air_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Air_Var_Id  
          If @Electric_Var_Id Is Not Null  
               Select @Electric_Sum = IsNull(@Electric_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Electric_Var_Id  
          If @Gas_Var_Id Is Not Null  
               Select @Gas_Sum = IsNull(@Gas_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Gas_Var_Id  
          If @Steam_Var_Id Is Not Null  
               Select @Steam_Sum = IsNull(@Steam_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Steam_Var_Id  
          If @Water_Var_Id Is Not Null  
               Select @Water_Sum = IsNull(@Water_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Water_Var_Id  
  
          /************************************************************************************************  
          *                                     Get Next Record                                           *  
          ************************************************************************************************/  
          Fetch Next From ProductRuns Into @Prod_Id, @Prod_Desc, @GCAS_Char_Id, @GCAS, @Product_Start_Time, @Product_End_Time  
  
          /************************************************************************************************  
          *                                     Return Results                                            *  
          ************************************************************************************************/  
          /* If finished adding up data for a single product or no more products then return data */  
          If (@Last_Prod_Id <> @Prod_Id And @Last_GCAS <> @GCAS) Or @@FETCH_STATUS <> 0  
               Begin  
               /* Get total furnish */  
               Select @Furnish_Sum =  isnull(@3rd_Furnish_Sum, 0) +  
     isnull(@CTMP_Sum, 0) +  
     isnull(@Fiber_1_Sum, 0) +  
     isnull(@Fiber_2_Sum, 0) +  
     isnull(@Long_Fiber_Sum, 0) +  
     isnull(@Short_Fiber_Sum, 0) +  
     isnull(@Product_Broke_Sum, 0)  
  
               /* Insert Data */  
               Insert Into #Summary_Data (Plant,  
     Storage_Location,   
     Product,  
     Product_Time,  
     GCAS,  
     Reel_Tons,  
     Furnish,  
     Third_Furnish,  
     Absorb_Aid_Towel,  
     Biocide,       Cat_Promoter,  
     Chem_1,  
     Chem_2,  
     Chlorine_Control,  
     CTMP,  
     Defoamer,  
     Dry_Strength_Tissue,  
     Dry_Strength_Towel,  
     Dye_1,  
     Dye_2,  
     Emulsion_1,  
     Emulsion_2,  
     Fiber_1,  
     Fiber_2,  
     Flocculant,  
     Glue_Adhesive,  
     Glue_Crepe_Aid,  
     Glue_Release_Aid,  
     Glue_Total,  
     Long_Fiber,  
--     Machine_Broke,  
     pH_Control_Tissue_Acid,  
     pH_Control_Towel_Base,  
     Product_Broke,  
     Short_Fiber,  
     Single_Glue,  
     Softener_Tissue,  
     Softener_Towel,  
     Steam,  
     Air,  
     Wet_Strength_Tissue,  
     Wet_Strength_Towel,  
     Electric,  
     Gas,  
     Water)  
                Values (  @Plant,  
     @Storage_Location,  
     @Last_Prod_Desc,  
     @Product_Time,  
     @GCAS,  
     @Reel_Tons_Sum,  
     @Furnish_Sum * @LB_Conversion / @KG_Conversion,  
     @3rd_Furnish_Sum * @LB_Conversion / @KG_Conversion,  
     @Absorb_Aid_Towel_Sum / @KG_Conversion,  
     @Biocide_Sum / @KG_Conversion,  
     @Cat_Promoter_Sum / @KG_Conversion,  
     @Chem_1_Sum / @KG_Conversion,  
     @Chem_2_Sum / @KG_Conversion,  
     @Chlorine_Control_Sum / @KG_Conversion,  
     @CTMP_Sum * @LB_Conversion / @KG_Conversion,  
     @Defoamer_Sum / @KG_Conversion,  
     @Dry_Strength_Tissue_Sum / @KG_Conversion,  
     @Dry_Strength_Towel_Sum / @KG_Conversion,  
     @Dye_1_Sum / @KG_Conversion,  
     @Dye_2_Sum / @KG_Conversion,  
     @Emulsion_1_Sum / @KG_Conversion,  
     @Emulsion_2_Sum / @KG_Conversion,  
     @Fiber_1_Sum * @LB_Conversion / @KG_Conversion,  
     @Fiber_2_Sum * @LB_Conversion / @KG_Conversion,  
     @Flocculant_Sum / @KG_Conversion,  
     @Glue_Adhesive_Sum / @KG_Conversion,  
     @Glue_Crepe_Aid_Sum / @KG_Conversion,  
     @Glue_Release_Aid_Sum / @KG_Conversion,  
     @Glue_Total_Sum / @KG_Conversion,  
     @Long_Fiber_Sum * @LB_Conversion / @KG_Conversion,  
--     @Machine_Broke_Sum * @LB_Conversion / @KG_Conversion,  
     @pH_Control_Tissue_Acid_Sum / @KG_Conversion,  
     @pH_Control_Towel_Base_Sum / @KG_Conversion,  
     @Product_Broke_Sum * @LB_Conversion / @KG_Conversion,  
     @Short_Fiber_Sum * @LB_Conversion / @KG_Conversion,  
     @Single_Glue_Sum / @KG_Conversion,  
     @Softener_Tissue_Sum / @KG_Conversion,  
     @Softener_Towel_Sum / @KG_Conversion,  
     @Steam_Sum / @KG_Conversion,  
     @Air_Sum / @KG_Conversion,  
     @Wet_Strength_Tissue_Sum / @KG_Conversion,  
     @Wet_Strength_Towel_Sum / @KG_Conversion,  
     @Electric_Sum,  
     @Gas_Sum,  
     @Water_Sum)  
  
               If @@FETCH_STATUS = 0  
                    Begin  
                    /* Reinitialize */  
                    Select  @Product_Time    = Null,  
   @Reel_Tons_Sum    = Null,  
   @Furnish_Sum    = Null,  
   @3rd_Furnish_Sum    = Null,  
   @Absorb_Aid_Towel_Sum   = Null,  
   @Biocide_Sum     = Null,  
   @Cat_Promoter_Sum    = Null,  
   @Chem_1_Sum    = Null,  
   @Chem_2_Sum    = Null,  
   @Chlorine_Control_Sum    = Null,  
   @CTMP_Sum     = Null,  
   @Defoamer_Sum    = Null,  
   @Dry_Strength_Tissue_Sum  = Null,  
   @Dry_Strength_Towel_Sum   = Null,  
   @Dye_1_Sum     = Null,  
   @Dye_2_Sum     = Null,  
   @Emulsion_1_Sum    = Null,  
   @Emulsion_2_Sum    = Null,  
   @Fiber_1_Sum     = Null,  
   @Fiber_2_Sum     = Null,  
   @Flocculant_Sum    = Null,  
   @Glue_Adhesive_Sum    = Null,  
   @Glue_Crepe_Aid_Sum    = Null,  
   @Glue_Release_Aid_Sum   = Null,  
   @Glue_Total_Sum    = Null,  
   @Long_Fiber_Sum    = Null,  
   @Machine_Broke_Sum    = Null,  
   @pH_Control_Tissue_Acid_Sum   = Null,  
   @pH_Control_Towel_Base_Sum   = Null,  
   @Product_Broke_Sum    = Null,  
   @Short_Fiber_Sum    = Null,  
   @Single_Glue_Sum    = Null,  
   @Softener_Tissue_Sum   = Null,  
   @Softener_Towel_Sum   = Null,  
   @Wet_Strength_Tissue_Sum  = Null,  
   @Wet_Strength_Towel_Sum  = Null,  
   @Air_Sum    = Null,  
   @Electric_Sum    = Null,  
   @Gas_Sum    = Null,  
   @Steam_Sum    = Null,  
   @Water_Sum    = Null,  
   @Last_Prod_Id     = @Prod_Id,  
   @Last_Prod_Desc   = @Prod_Desc,  
   @Last_GCAS    = @GCAS  
                    End  
               End  
          End  
  
  
/************************************************************************************************  
*                                   Return Data                                                                        *  
************************************************************************************************/  
Select *  
From #Summary_Data  
  
/************************************************************************************************  
*                                     Cleanup                                                                            *  
************************************************************************************************/  
  
-- Drop Table #Production_Runs  
Drop Table #Summary_Data  
Close ProductRuns  
Deallocate ProductRuns  
  
/* Testing....  
Select @Time5 = getdate()  
Select Datediff(ms, @Time1, @Time5), Datediff(ms, @Time1, @Time2), Datediff(ms, @Time2, @Time3), Datediff(ms, @Time3, @Time4), Datediff(ms, @Time4, @Time5)  
*/  
  
