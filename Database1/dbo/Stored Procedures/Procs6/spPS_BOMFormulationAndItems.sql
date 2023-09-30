
CREATE PROCEDURE [dbo].[spPS_BOMFormulationAndItems]
@paramId bigint,
@paramType nvarchar(200),
@bomFormulationDescription nvarchar(255) = Null,
@PageNumber Int  = Null, -- Current page number,
@PageSize Int  = Null -- Total records per page to display

AS

/*---------------------------------------------------------------------------------------------------------------------
    This SP retrieves data for BOM Formulation(s), BOM Formulation Items, BOM Masters and BOM Familys
  
    Date         Ver/Build   Author               Story/Defect       Remarks
    03-Aug-2018  001         Tejasvi              US266160/US266212  Added procedure to Retreive the BOM Formulation data
    16-Aug-2018  002         503065767                               Bom Formulation Fixes.
    07-Sep-2018  003         503065772                               Modified as part of API review changes
    14-Nov-2018  004         503065767                               Updated Engineering unit and unitofmeasure Validation
    18-Apr-2019  005         Sravanthi                               Added BomFormulationDescription to Product id search
    15-May-2019  006         503070943                               Encrypted stored procedures
    21-May-2019  007         503128786                               changes related to new api (get formulation record based on formulation id).
    27-May-2019  008         503128786                               changes related to bom formulations.
    11-Jun-2019  009         503065767            DE111524           500 Internal Server Error obtaining when get BOM Formulation
                                                                      by Maximum length BOM Formulation Id as a input
    12-Jun-2019  010         503070943            US345689           Revoke Encrypted stored procedures
    16-Jun-2020  011         Sireesha                                Updated db Scripts
    01-Jul-2020  012         Sireesha                                modifications for bom item creation and fetch list
    28-Jul-2020  012         Venkat                                  modified for defects
    04-Aug-2020  013         Dan Stephens         DE140006           Updated the section for "PRODUCTID" to fix searching by specific ProductId
    01-Sept-2020 014         Suman                                   Not returning PU_Id column for get formulation by id as its not used in service.
    25-Sep-2020  015         Dan Stephens         DE144132           Updated "FORMULATIONID" section to order returned items by "Bom_Formulation_Order"
    10-Oct-2020  016         Suman         		  			         Get BOM family by id and BOM master by id

---------------------------------------------------------------------------------------------------------------------
    PARAMETERS:
        @paramType: Formulations : PRODUCTID, ONE_FORMULATION_BY_FORMULATIONID,
                    Items        : FORMULATIONID, FORMULATIONITEM_ID, FORMULATIONITEM_DETAILS, FORMULATIONITEM_ALTERNATE, FORMULATIONITEM_SUBSTITUTION,
                    Family/Master: BOM_FAMILY, BOM_MASTER, BOM_FAMILY_BY_ID, BOM_MASTER_BY_ID

    NOTES:
        - Historic details of modifications before ver 013 mainly taken from Git commit details.
    
---------------------------------------------------------------------------------------------------------------------*/



BEGIN

/* START 'PRODUCTID' - Getting a list of BOM Formulations by ProductId, returning full list if ProductId is empty */
IF(@paramType='PRODUCTID')
    BEGIN
        DECLARE @StartPosition INT = @PageSize * (@PageNumber - 1);
        DECLARE @TotalRecords  INT = 0;

        /* IF the ProductId (@paramId) is NULL/empty, run one version of the query */
        IF (@paramId IS NULL)
            BEGIN

                SELECT bform.BOM_Formulation_Id,
                       bform.BOM_Formulation_Code,
                       bform.BOM_Formulation_Desc,
                       bform.BOM_Id,
                       bform.Effective_Date,
                       bform.Expiration_Date,
                       bform.Standard_Quantity,
                       bform.Quantity_Precision,
                       unit.eng_Unit_Id,
                       details.Revision,              
                       details.Status,
                       details.Created_By,
                       details.Created_On,
                       details.Last_Modified_By,
                       details.Last_Modified_On,
                       (SELECT ','+CAST(Prod_Id AS VARCHAR) FROM dbo.Bill_Of_Material_Product prod JOIN dbo.Bill_Of_Material_Formulation t ON prod.BOM_Formulation_Id = t.BOM_Formulation_Id
                         WHERE t.BOM_Formulation_Id = bform.BOM_Formulation_Id
                           FOR XML PATH(''), TYPE).value('substring(text()[1], 2)', 'varchar(max)') AS Prod_Id,
                       COUNT(0) OVER() totalRecords
                  FROM           dbo.Bill_Of_Material_Formulation          bform
                       LEFT JOIN dbo.Bill_Of_Material_Formulation_Revision details ON bform.BOM_Formulation_Id = details.BOM_Formulation_Id
                       JOIN      dbo.Engineering_unit                      unit    ON bform.eng_Unit_Id = unit.eng_Unit_Id 
                 WHERE (@bomFormulationDescription IS NULL  OR
                        bform.BOM_Formulation_Desc = @bomFormulationDescription)
                 ORDER
                    BY details.Last_Modified_On DESC,
                       bform.BOM_Formulation_Id DESC
                OFFSET @StartPosition ROWS
                FETCH  NEXT @PageSize ROWS ONLY;

            END;

        /* ELSE if the ProductId (@paramId) has a value, run the alternate version of the query */
        ELSE
            BEGIN

                SELECT bform.BOM_Formulation_Id,
                       bform.BOM_Formulation_Code,
                       bform.BOM_Formulation_Desc,
                       bform.BOM_Id,
                       bform.Effective_Date,
                       bform.Expiration_Date,
                       bform.Standard_Quantity,
                       bform.Quantity_Precision,
                       unit.eng_Unit_Id,
                       details.Revision,              
                       details.Status,
                       details.Created_By,
                       details.Created_On,
                       details.Last_Modified_By,
                       details.Last_Modified_On,
                       (SELECT ','+CAST(Prod_Id AS VARCHAR) FROM dbo.Bill_Of_Material_Product prod JOIN dbo.Bill_Of_Material_Formulation t ON prod.BOM_Formulation_Id = t.BOM_Formulation_Id
                         WHERE t.BOM_Formulation_Id = bform.BOM_Formulation_Id
                           FOR XML PATH(''), TYPE).value('substring(text()[1], 2)', 'varchar(max)') AS Prod_Id,
                       COUNT(0) OVER() totalRecords
                  FROM           dbo.Bill_Of_Material_Formulation          bform
                       LEFT JOIN dbo.Bill_Of_Material_Formulation_Revision details ON bform.BOM_Formulation_Id = details.BOM_Formulation_Id
                       JOIN      dbo.Engineering_unit                      unit    ON bform.eng_Unit_Id = unit.eng_Unit_Id
                       JOIN      dbo.Bill_Of_Material_Product              prod    ON bform.BOM_Formulation_Id=prod.BOM_Formulation_Id
                 WHERE (@bomFormulationDescription IS NULL  OR
                        bform.BOM_Formulation_Desc = @bomFormulationDescription)
                   AND (prod.Prod_Id = @paramId)
                 ORDER
                    BY details.Last_Modified_On DESC,
                       bform.BOM_Formulation_Id DESC
                OFFSET @StartPosition ROWS
                FETCH  NEXT @PageSize ROWS ONLY;

            END;
                   
    END;
/* END 'PRODUCTID' */



IF(@paramType='ONE_FORMULATION_BY_FORMULATIONID')
       BEGIN
               select
                        bform.BOM_Formulation_Id,
                        bform.BOM_Formulation_Code,
                        bform.BOM_Formulation_Desc,
                        bform.BOM_Id,
                        bform.Effective_Date,
                        bform.Expiration_Date,
                        bform.Standard_Quantity,
                        bform.Quantity_Precision,
                        unit.eng_Unit_Id,
                        details.Revision,
                        details.Status,
                        details.Created_By,
                        details.Created_On,
                        details.Last_Modified_By,
                        details.Last_Modified_On,
                        (select ','+CAST(Prod_Id AS varchar) from dbo.Bill_Of_Material_Product as CM where BOM_Formulation_Id=@paramId for xml path(''), type).value('substring(text()[1], 2)', 'varchar(max)') as Prod_Id,
                        COUNT(0) OVER() totalRecords
              from
                    Bill_Of_Material_Formulation bform
                    left join Bill_Of_Material_Formulation_Revision details on bform.BOM_Formulation_Id=details.BOM_Formulation_Id
                    inner join Engineering_unit unit on bform.eng_Unit_Id=unit.eng_Unit_Id 
              where               
                    bform.BOM_Formulation_Id=@paramId;
       END;
   


/* For fetching all formulation items by formulation id*/
ELSE IF(@paramType='FORMULATIONID')
    BEGIN
        SELECT p.prod_id,
               bomfi.BOM_Formulation_Item_Id,
               bomfi.Quantity,
               unit.eng_Unit_Id,
               bomfi.Lower_Tolerance,
               bomfi.Upper_Tolerance,
               bomfi.PU_ID,
               bomfi.BOM_Formulation_Order,
               bomfi.Alias,
               bomfi.Scrap_Factor,
               bomfi.LTolerance_Precision,
               bomfi.UTolerance_Precision,
               bomfi.Quantity_Precision,
               bomfi.Use_Event_Components
          FROM Bill_Of_Material_Formulation_Item bomfi
               JOIN Engineering_unit unit on bomfi.eng_Unit_Id=unit.eng_Unit_Id 
               JOIN Products         p    on bomfi.Prod_Id=p.Prod_Id 
         WHERE bomfi.BOM_Formulation_Id=@paramId
         ORDER
            BY bomfi.BOM_Formulation_Order;

       END;



/* For fetching formulation items by formulation item id*/
ELSE IF(@paramType='FORMULATIONITEM_ID')
    BEGIN
        SELECT p.prod_id,
               bomfi.BOM_Formulation_Item_Id,
               bomfi.Quantity,
               unit.eng_Unit_Id,
               bomfi.Lower_Tolerance,
               bomfi.Upper_Tolerance,
               bomfi.PU_ID,
               bomfi.BOM_Formulation_Order,
               bomfi.Alias,
               bomfi.Scrap_Factor,
               bomfi.LTolerance_Precision,
               bomfi.UTolerance_Precision,
               bomfi.Quantity_Precision,
               bomfi.Use_Event_Components
          FROM Bill_Of_Material_Formulation_Item bomfi
               JOIN Engineering_unit unit on bomfi.eng_Unit_Id=unit.eng_Unit_Id 
               JOIN Products         p    on bomfi.Prod_Id=p.Prod_Id 
         WHERE bomfi.Bom_formulation_item_id=@paramId;
    END;



ELSE IF(@paramType='BOM_FAMILY')
        BEGIN
            select  
					bomfm.BOM_Family_Id,
					bomfm.BOM_Family_Desc
              from  Bill_Of_Material_Family bomfm;
        END;

ELSE IF(@paramType='BOM_FAMILY_BY_ID')
        BEGIN
           select  
					bomfm.BOM_Family_Id,
					bomfm.BOM_Family_Desc
              from  Bill_Of_Material_Family bomfm
              WHERE bomfm.BOM_Family_Id = @paramId
        END;

ELSE IF(@paramType='BOM_MASTER')
        BEGIN
            select  
					bom.BOM_Id,
					bom.BOM_Desc,
					bom.BOM_Family_Id,
					bom.Is_Active
              from  Bill_Of_Material bom;
        END;

ELSE IF(@paramType='BOM_MASTER_BY_ID')
        BEGIN
            select  
					bom.BOM_Id,
					bom.BOM_Desc,
					bom.BOM_Family_Id,
					bom.Is_Active
              from  Bill_Of_Material bom
              WHERE bom.BOM_Id = @paramId
        END;

END;

 
 