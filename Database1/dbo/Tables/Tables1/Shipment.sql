CREATE TABLE [dbo].[Shipment] (
    [Shipment_Id]     INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Arrival_Date]    DATETIME     NULL,
    [Carrier_Code]    VARCHAR (25) NULL,
    [Carrier_Type]    VARCHAR (10) NULL,
    [COA_Date]        DATETIME     NULL,
    [Comment_Id]      INT          NULL,
    [Complete_Date]   DATETIME     NULL,
    [Is_Active]       BIT          CONSTRAINT [DF_Shipment_Is_Active] DEFAULT ((1)) NOT NULL,
    [Shipment_Date]   DATETIME     NOT NULL,
    [Shipment_Number] VARCHAR (50) NOT NULL,
    [Vehicle_Name]    VARCHAR (25) NULL,
    CONSTRAINT [Shipment_PK_ShipmentId] PRIMARY KEY CLUSTERED ([Shipment_Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [Shipment_IDX_Number]
    ON [dbo].[Shipment]([Shipment_Number] ASC);


GO
CREATE TRIGGER dbo.Shipment_Del ON dbo.Shipment
  FOR DELETE
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare 
 	 @Comment_Id int
DECLARE Shipment_Del_Cursor CURSOR
  FOR SELECT Comment_Id FROM DELETED WHERE Comment_Id IS NOT NULL 
  FOR READ ONLY
OPEN Shipment_Del_Cursor 
--
--
Fetch_Shipment_Del:
FETCH NEXT FROM Shipment_Del_Cursor INTO @Comment_Id
IF @@FETCH_STATUS = 0
  BEGIN
    Delete From Comments Where TopOfChain_Id = @Comment_Id 
    Delete From Comments Where Comment_Id = @Comment_Id 
    GOTO Fetch_Shipment_Del
  END
ELSE IF @@FETCH_STATUS <> -1
  BEGIN
    RAISERROR('Fetch error in Shipment_Del (@@FETCH_STATUS = %d).', 11,
      -1, @@FETCH_STATUS)
  END
DEALLOCATE Shipment_Del_Cursor 

GO
CREATE TRIGGER [dbo].[Shipment_TableFieldValue_Del]
 ON  [dbo].[Shipment]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.Shipment_Id
 WHERE tfv.TableId = 48
