

--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CTS_Get_Appliances 
--------------------------------------------------------------------------------------------------
-- Author				:	F. Bergeron	, Symasol
-- Date created			:	2021-08-12
-- Version 				:	Version <1.0>
-- SP Type				:	Web
-- Caller				:	Called by CTS mobile application
-- Description			:	The purpose of this query is to get the appliances by different criteria
/*
							The SP returns
							Serial
							Appliance_id
							Appliance_desc
							Appliance_Type
							Cleaning_status
							Active_or_inprep_PP_Id
							Active_or_inprep_process_order
							Active_or_inprep_process_order_product_Id
							Active_or_inprep_process_order_product_code
							Active_or_inprep_process_order_status
							Reservation_type
							Reservation_PU_Id
							Reservatio_PU_Desc
							Reservation_PP_Id
							Reservation_Process_Order
							Reservation_Product_Id
							Reservation_Product_Code
							Action_Reservation_Is_Active
							Action_Cleaning_Is_Active
							Action_Movement_Is_Active
*/

-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
--
--
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2021-08-12		F. Bergeron				Initial Release 

--================================================================================================
--


--------------------------------------------------------------------------------------------------
-- TEST CODE:
-- EXECUTE spLocal_CTS_Get_Appliances 
--------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[spLocal_CTS_Get_Appliances]
               @F_Appliance_Id  INTEGER                             = NULL,
               @F_Product VARCHAR(255)   = NULL,
               @F_Appliance_status  VARCHAR(25)                    = NULL,
               @F_Appliance_location  VARCHAR(255)   = NULL,
               @F_Appliance_type VARCHAR(255)   = NULL,
               @C_User_Id INTEGER                                            = NULL


AS
BEGIN
               SET NOCOUNT ON;
               -- SP Variables

               DECLARE 
               @ApplianceEventId                                                       INTEGER

               DECLARE
               @Output TABLE
               (
                              Serial                                                                                                                                                           VARCHAR(25),
                              Appliance_Id                                                                                                                               INTEGER,
                              Appliance_desc                                                                                                                          VARCHAR(50),
                              Appliance_Type                                                                                                                         VARCHAR(50),
                              Appliance_location_Id                                                                                              INTEGER,
                              Appliance_location_Desc                                                                                                        VARCHAR(50),
                              Cleaning_status                                                                                                                         VARCHAR(25),
                              Cleaning_Type                                                                                                                           VARCHAR(25),
                              Cleaning_PU_Id                                                                                                                         INTEGER,
                              Cleaning_PU_Desc                                                                                                                    VARCHAR(50),    
                              Appliance_PP_Id                                                                                                                                       INTEGER,
                              Appliance_process_order                                                                                                        VARCHAR(50),
                              Appliance_process_order_product_Id                                                   INTEGER,
                              Appliance_process_order_product_code                                             VARCHAR(50),
                              Appliance_process_order_status_Id                                                      INTEGER,
                              Appliance_process_order_status_Desc                                                 VARCHAR(50),
                              Reservation_type                                                                                                                      VARCHAR(25),
                              Reservation_PU_Id                                                                                                                   INTEGER,
                              Reservation_PU_Desc                                                                                                              VARCHAR(50),
                              Reservation_PP_Id                                                                                                                    INTEGER,
                              Reservation_Process_Order                                                                                    VARCHAR(50),
                              Reservation_Product_Id                                                                                                          INTEGER,
                              Reservation_Product_Code                                                                                     VARCHAR(50),
                              Action_Reservation_Is_Active                                                                  BIT,
                              Action_Cleaning_Is_Active                                                                                       BIT,
                              Action_Movement_Is_Active                                                                                  BIT,
                              Access                                                                                                                                                         VARCHAR(25),
                              Err_Warn                                                                                                                                                    VARCHAR(500)
                                                                                                         
               )

               -- AT THIS STAGE  USER HAS ACCESS TO CTS
               DECLARE 
               @FProducts TABLE
               (
                              Product_Id                                                                                     INTEGER,
                              Product_desc                                                  INTEGER
               )
               DECLARE 
               @FAppliance_locations TABLE
               (
                              PU_Id                                                                               INTEGER,
                              PU_Desc                                                                                         VARCHAR(50)
               )

                              
               DECLARE 
               @FAppliance_types TABLE
               (
                              PU_Id                                                                               INTEGER,
                              PU_Desc                                                                                         VARCHAR(50),
                              Type                                                                                 VARCHAR(50)
               )
               
               DECLARE 
               @FStatuses TABLE
               (
                              Status_id                                                                         INTEGER,
                              Status_Desc                                                                    VARCHAR(50)
               )


                              INSERT INTO @FProducts(Product_id)
                              SELECT CAST(value AS INTEGER) FROM STRING_SPLIT(@F_Product, ',');

                              INSERT INTO @FStatuses (Status_Desc)
                              SELECT VALUE FROM STRING_SPLIT(@F_Appliance_Status, ',');

                              IF (SELECT           COUNT(VALUE) 
                                             FROM    STRING_SPLIT(@F_Appliance_Status, ',')) > 0
                                             DELETE @FAppliance_locations WHERE PU_Id NOT IN(SELECT CAST(VALUE AS INTEGER) FROM STRING_SPLIT(@F_Appliance_Status, ','))
                              
                              INSERT INTO @FAppliance_types (Type)
                              SELECT VALUE FROM STRING_SPLIT(@F_Appliance_type, ',');
                              

                              IF (SELECT COUNT(1) FROM @FProducts) = 0
                                             INSERT INTO @Fproducts (Product_Id)
                                             SELECT prod_id FROM dbo.Products_Base

                              UPDATE @FAppliance_types SET PU_Id = 
                                             TFV.KeyId, PU_DESC = PUB.PU_Desc                                      
                                             FROM    dbo.Table_Fields_Values TFV
                                                                           JOIN dbo.table_fields TF ON TF.Table_Field_Id = TFV.Table_Field_Id
                    JOIN dbo.Tables T ON t.tableid = TF.tableId
                                                                                          AND T.tableName = 'Prod_Units'
                                                                           JOIN dbo.prod_units_base PUB WITH(NOLOCK)
                                                                                          ON  PUB.pu_id = TFV.KeyId
                                             WHERE   Table_Field_Desc = 'CTS Appliance type' AND TFV.Value = Type

                  IF (SELECT COUNT(1) FROM @FAppliance_types) = 0
                                             INSERT INTO  @FAppliance_types (PU_Id,Type) 
                                             SELECT TFV.KeyId, TFV.Value                                     
                                             FROM    dbo.Table_Fields_Values TFV
                                                                           JOIN dbo.table_fields TF ON TF.Table_Field_Id = TFV.Table_Field_Id
                    JOIN dbo.Tables T ON t.tableid = TF.tableId
                                                                                          AND T.tableName = 'Prod_Units'
                                             WHERE   Table_Field_Desc = 'CTS Appliance type'

                              
                              INSERT INTO @FAppliance_locations (PU_ID, PU_Desc)
                                             SELECT  PU_ID, PU_Desc
                                             FROM    dbo.Prod_Units_Base PUB WITH(NOLOCK) 
                                             WHERE PUB.Equipment_Type = 'CTS location'
                              

               -- GET APPLIANCES
               -- EVENT ID IN LOCATION, PO, STATUS

               IF @F_Appliance_Id IS NULL -- GET a list of locations
               BEGIN
                              INSERT INTO @Output
                              (
                                             Serial,
                                             Appliance_Id,
                                             Appliance_desc,
                                             Appliance_Type,
                                             Appliance_location_Id,
                                             Appliance_location_Desc,
                                             Cleaning_status,
                                             Cleaning_Type,
                                             Cleaning_PU_Id,
                                             Cleaning_PU_Desc,          
                                             Appliance_PP_Id,
                                             Appliance_process_order,
                                             Appliance_process_order_product_Id,
                                             Appliance_process_order_product_code,
                                             Appliance_process_order_status_Id,
                                             Appliance_process_order_status_Desc,
                                             Reservation_type,
                                             Reservation_PU_Id,
                                             Reservation_PU_Desc,
                                             Reservation_PP_Id,
                                             Reservation_Process_Order,
                                             Reservation_Product_Id,
                                             Reservation_Product_Code,
                                             Action_Reservation_Is_Active,
                                             Action_Cleaning_Is_Active,
                                             Action_Movement_Is_Active,
                                             Access,
                                             Err_Warn

                              )
                              SELECT  EDAPP.Alternate_event_num 'Serial',
                                                            EAPP.event_id 'Appliance_Id',
                                                            EAPP.event_num 'Appliance _desc',
                                                            FAT.type 'Appliance_Type',
                                                            FAL.PU_Id 'Appliance_location_Id',
                                                            FAL.PU_Desc 'Appliance_location_Desc',
                                                            APPCL.status 'Cleaning_status',
                                                            APPCL.Type 'Cleaning_Type',
                                                            APPCL.Location_Id 'Cleaning_PU_Id',
                                                            APPCL.Location_desc  'Cleaning_PU_Desc',           
                                                            POINFO.PP_Id 'Appliance_PP_Id',
                                                            POINFO.Process_Order 'Appliance_process_order',
                                                            POINFO.Prod_Id 'Appliance_process_order_product_Id',
                                                            POP.Prod_Code 'Appliance_process_order_product_code',
                                                            POINFO.PP_Status_Id 'Appliance_process_order_status_Id',
                                                            PPSt.PP_Status_Desc 'Appliance_process_order_status_Desc',
                                                            APRES.Reservation_type 'Reservation_type',
                                                            APRES.Reservation_PU_Id 'Reservation_PU_Id',
                                                            APRES.Reservation_PU_Desc 'Reservation_PU_Desc',
                                                            APRES.Reservation_PP_Id 'Reservation_PP_Id',
                                                            APRES.Reservation_Process_Order 'Reservation_Process_Order',
                                                            APRES.Reservation_Product_Id 'Reservation_Product_Id',
                                                            APRES.Reservation_Product_Code 'Reservation_Product_Code',
                                                            1 'Action_Reservation_Is_Active',
                                                            1 'Action_Cleaning_Is_Active',
                                                            1 'Action_Movement_Is_Active',
                                                            'Manager' 'Acess',
                                                            (CASE
                                                                                          WHEN PPU.PU_Id IS NOT NULL AND POSINFO.PP_Id IS NULL
                                                                                                         THEN 'Illegal movement, PO should be set at this location'
                                                                                          ELSE
                                                                                                         ''
                                                                                          END) 'Err_Warn'
                              FROM    dbo.Prod_Units_Base PUB WITH(NOLOCK)
                                                            JOIN @FAppliance_types FAT ON FAT.PU_Id = PUB.PU_Id
                                                            INNER JOIN dbo.events EAPP WITH(NOLOCK) ON EAPP.PU_Id = PUB.PU_Id -- APPLIANCE UNITS
                                                            LEFT JOIN dbo.event_details EDAPP WITH(NOLOCK) ON EDAPP.Event_Id = EAPP.Event_Id
                                                            OUTER APPLY (SELECT TOP 1 * FROM dbo.event_components EC WITH(NOLOCK) WHERE EC.Source_Event_Id = EAPP.Event_id ORDER BY timestamp DESC) AS ECLTRANS -- WHERE THE APPLIANCE IS NOW
                                                            LEFT JOIN dbo.events ELTRANS WITH(NOLOCK) ON ELTRANS.Event_Id = ECLTRANS.Event_Id
                                                            LEFT JOIN dbo.Prod_Units_Base PULTRANS WITH(NOLOCK) ON PULTRANS.PU_id = ELTRANS.PU_Id
                                                            LEFT JOIN @FAppliance_locations FAL ON FAL.pu_id = ELTRANS.pu_id
                                             -- CLEANING
                                                            OUTER APPLY 
                                                            (              
                                                                           SELECT  Status,
                                                                                                         type,
                                                                                                         Location_id,
                                                                                                         Location_desc,
                                                                                                         Start_time,
                                                                                                         End_time,
																										Approver_ES_User_Id
                                                                                                         Approver_ES_Username,
                                                                                                         Err_Warn
                                                                           FROM               [dbo].[fnLocal_CTS_Appliance_Cleanings](EAPP.event_id, NULL, NULL)
                                                            ) AS APPCL

                                             -- RESERVATION
                                                            OUTER APPLY 
                                                            (              
                                                                           SELECT  Appliance_Serial,
                                                                                                         Appliance_Type,
                                                                                                         Reservation_Status,
                                                                                                         Reservation_type,
                                                                                                         Reservation_PU_Id,
                                                                                                         Reservation_PU_Desc,
                                                                                                         Reservation_PP_Id,
                                                                                                         Reservation_Process_Order,
                                                                                                         Reservation_Product_Id,
                                                                                                         Reservation_Product_Code,
                                                                                                         Reservation_creation_User_Id,
                                                                                                         Reservation_creation_User_Desc
                                                                           FROM               [dbo].[fnLocal_CTS_Appliance_Reservations](EAPP.event_id, NULL, NULL)
                                                            ) AS APRES
                                             -- PROCESS ORDER
                                                            LEFT JOIN dbo.PrdExec_Path_Units PPULTRANS WITH(NOLOCK) ON PPULTRANS.PU_ID = ELTRANS.PU_ID
                                                            LEFT JOIN dbo.PrdExec_Path_Units PPULTRANSG WITH(NOLOCK) ON PPULTRANSG.Path_Id = PPULTRANS.Path_Id AND PPULTRANSG.Is_Schedule_Point = 1
                                                            -- ALL UNITS OF THE PATH STARTS SIMULTANOUSLY
                                                            OUTER APPLY (SELECT TOP 1 * FROM dbo.Production_Plan_Starts PPS WITH(NOLOCK) WHERE EAPP.timestamp >= PPS.start_time AND (EAPP.timestamp < PPS.end_time OR PPS.end_time IS NULL) AND PPS.PU_id = ELTRANS.PU_id  ORDER BY PPS.Start_Time DESC) AS POSINFO
                                                            LEFT JOIN dbo.production_plan POINFO ON POINFO.PP_ID = POSINFO.PP_ID
                                                            LEFT JOIN dbo.products_Base POP WITH(NOLOCK) ON POP.Prod_Id = POINFO.Prod_Id 
                                                                           AND POP.Prod_Id IN(SELECT Product_Id FROM @FProducts)
                                                            LEFT JOIN dbo.Production_Plan_Statuses PPSt WITH(NOLOCK)
                                                                                          ON PPSt.PP_Status_Id = POINFO.PP_Status_Id
                                                            LEFT JOIN dbo.PrdExec_Path_Units PPU WITH(NOLOCK)
                                                                                          ON PPU.pu_id = FAL.pu_id
                              
               END
               ELSE
               BEGIN
                              INSERT INTO @Output
                              (
                                             Serial,
                                             Appliance_Id,
                                             Appliance_desc,
                                             Appliance_Type,
                                             Appliance_location_Id,
                                             Appliance_location_Desc,
                                             Cleaning_status,
                                             Cleaning_Type,
                                             Cleaning_PU_Id,
                                             Cleaning_PU_Desc,          
                                             Appliance_PP_Id,
                                             Appliance_process_order,
                                             Appliance_process_order_product_Id,
                                             Appliance_process_order_product_code,
                                             Appliance_process_order_status_Id,
                                             Appliance_process_order_status_Desc,
                                             Reservation_type,
                                             Reservation_PU_Id,
                                             Reservation_PU_Desc,
                                             Reservation_PP_Id,
                                             Reservation_Process_Order,
                                             Reservation_Product_Id,
                                             Reservation_Product_Code,
                                             Action_Reservation_Is_Active,
                                             Action_Cleaning_Is_Active,
                                             Action_Movement_Is_Active,
                                             Access,
                                             Err_Warn

                              )
                              SELECT 
                                             EDAPP.Alternate_event_num 'Serial',
                                             EAPP.event_id 'Appliance_Id',
                                             EAPP.event_num 'Appliance _desc',
                                             FAT.type 'Appliance_Type',
                                             FAL.PU_Id 'Appliance_location_Id',
                                             FAL.PU_Desc 'Appliance_location_Desc',
                                             APPCL.status 'Cleaning_status',
                                             APPCL.Type 'Cleaning_Type',
                                             APPCL.Location_Id 'Cleaning_PU_Id',
                                             APPCL.Location_desc  'Cleaning_PU_Desc',           
                                             POINFO.PP_Id 'Appliance_PP_Id',
                                             POINFO.Process_Order 'Appliance_process_order',
                                             POINFO.Prod_Id 'Appliance_process_order_product_Id',
                                             POP.Prod_Code 'Appliance_process_order_product_code',
                                             POINFO.PP_Status_Id 'Appliance_process_order_status_Id',
                                             PPSt.PP_Status_Desc 'Appliance_process_order_status_Desc',
                                             APRES.Reservation_type 'Reservation_type',
                                             APRES.Reservation_PU_Id 'Reservation_PU_Id',
                                             APRES.Reservation_PU_Desc 'Reservation_PU_Desc',
                                             APRES.Reservation_PP_Id 'Reservation_PP_Id',
                                             APRES.Reservation_Process_Order 'Reservation_Process_Order',
                                             APRES.Reservation_Product_Id 'Reservation_Product_Id',
                                             APRES.Reservation_Product_Code 'Reservation_Product_Code',
                                             1 'Action_Reservation_Is_Active',
                                             1 'Action_Cleaning_Is_Active',
                                             1 'Action_Movement_Is_Active',
                                             'Manager' 'Acess',
                                             (CASE
                                                                           WHEN PPU.PU_Id IS NOT NULL AND POSINFO.PP_Id IS NULL
                                                                                          THEN 'Illegal movement, PO should be set at this location'
                                                                           ELSE
                                                                                          ''
                                                                           END) 'Err_Warn'
                              FROM dbo.Prod_Units_Base PUB WITH(NOLOCK)
                                                                           JOIN @FAppliance_types FAT ON FAT.PU_Id = PUB.PU_Id
                                                                           INNER JOIN dbo.events EAPP WITH(NOLOCK) ON EAPP.PU_Id = PUB.PU_Id -- APPLIANCE UNITS
                                                                           JOIN dbo.event_details EDAPP WITH(NOLOCK) ON EDAPP.Event_Id = EAPP.Event_Id
                                                                           OUTER APPLY (SELECT TOP 1 * FROM dbo.event_components EC WITH(NOLOCK) WHERE EC.Source_Event_Id = EAPP.Event_id ORDER BY timestamp DESC) AS ECLTRANS -- WHERE THE APPLIANCE IS NOW
                                                                           JOIN dbo.events ELTRANS WITH(NOLOCK) ON ELTRANS.Event_Id = ECLTRANS.Event_Id
                                                                           JOIN dbo.Prod_Units_Base PULTRANS WITH(NOLOCK) ON PULTRANS.PU_id = ELTRANS.PU_Id
                                                                           JOIN @FAppliance_locations FAL ON FAL.pu_id = ELTRANS.pu_id
                                             -- CLEANING
                                                                           OUTER APPLY 
                                                                           (              
                                                                           SELECT  Status,
                                                                                                         type,
                                                                                                         Location_id,
                                                                                                         Location_desc,
                                                                                                         Start_time,
                                                                                                         End_time,
                                                                                                         Approver_ES_User_AD,
                                                                                                         Approver_ES_Username,
                                                                                                         Err_Warn
                                                                           FROM               [dbo].[fnLocal_CTS_Appliance_Cleanings](EAPP.event_id, NULL, NULL)
                                                                           ) AS APPCL

                                             -- RESERVATION
                                                                           OUTER APPLY 
                                                                           (              
                                                                           SELECT  Appliance_Serial,
                                                                                                         Appliance_Type,
                                                                                                         Reservation_Status,
                                                                                                         Reservation_type,
                                                                                                         Reservation_PU_Id,
                                                                                                         Reservation_PU_Desc,
                                                                                                         Reservation_PP_Id,
                                                                                                         Reservation_Process_Order,
                                                                                                         Reservation_Product_Id,
                                                                                                         Reservation_Product_Code,
                                                                                                         Reservation_creation_User_Id,
                                                                                                         Reservation_creation_User_Desc
                                                                           FROM               [dbo].[fnLocal_CTS_Appliance_Reservations](EAPP.event_id, NULL, NULL)
                                                                           ) AS APRES
                                             -- PROCESS ORDER
                                                                           JOIN dbo.PrdExec_Path_Units PPULTRANS WITH(NOLOCK) ON PPULTRANS.PU_ID = ELTRANS.PU_ID
                                                                           JOIN dbo.PrdExec_Path_Units PPULTRANSG WITH(NOLOCK) ON PPULTRANSG.Path_Id = PPULTRANS.Path_Id AND PPULTRANSG.Is_Schedule_Point = 1
                                                                           -- ALL UNITS OF THE PATH STARTS SIMULTANOUSLY
                                                                           OUTER APPLY (SELECT TOP 1 * FROM dbo.Production_Plan_Starts PPS WITH(NOLOCK) WHERE EAPP.timestamp >= PPS.start_time AND (EAPP.timestamp < PPS.end_time OR PPS.end_time IS NULL) AND PPS.PU_id = ELTRANS.PU_id  ORDER BY PPS.Start_Time DESC) AS POSINFO
                                                                           LEFT JOIN dbo.production_plan POINFO ON POINFO.PP_ID = POSINFO.PP_ID
                                                                           LEFT JOIN dbo.products_Base POP WITH(NOLOCK) ON POP.Prod_Id = POINFO.Prod_Id 
                                                                                          AND POP.Prod_Id IN(SELECT Product_Id FROM @FProducts)
                                                                           LEFT JOIN dbo.Production_Plan_Statuses PPSt WITH(NOLOCK)
                                                                                                         ON PPSt.PP_Status_Id = POINFO.PP_Status_Id
                                                                           LEFT JOIN dbo.PrdExec_Path_Units PPU WITH(NOLOCK)
                                                                                                         ON PPU.pu_id = FAL.pu_id
                                                                           WHERE EAPP.event_id = @F_Appliance_Id
                              END
               SELECT  Serial,
                                             Appliance_Id,
                                             Appliance_desc,
                                             Appliance_Type,
                                             Appliance_location_Id,
                                             Appliance_location_Desc,
                                             Cleaning_status,
                                             Cleaning_Type,
                                             Cleaning_PU_Id,
                                             Cleaning_PU_Desc,          
                                             Appliance_PP_Id,
                                             Appliance_process_order,
                                             Appliance_process_order_product_Id,
                                             Appliance_process_order_product_code,
                                             Appliance_process_order_status_Id,
                                             Appliance_process_order_status_Desc,
                                             Reservation_type,
                                             Reservation_PU_Id,
                                             Reservation_PU_Desc,
                                             Reservation_PP_Id,
                                             Reservation_Process_Order,
                                             Reservation_Product_Id,
                                             Reservation_Product_Code,
                                             Action_Reservation_Is_Active,
                                             Action_Cleaning_Is_Active,
                                             Action_Movement_Is_Active,
                                             Access,
                                             Err_Warn
                              FROM @Output
END



RETURN
