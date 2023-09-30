CREATE TABLE [dbo].[UDEAttributeValues] (
    [Attribute_Id] INT            NOT NULL,
    [UDE_Id]       INT            NOT NULL,
    [Value]        VARCHAR (1000) NULL,
    CONSTRAINT [TrackingAttributeValues_PK_AttIdUDEId] PRIMARY KEY CLUSTERED ([UDE_Id] ASC, [Attribute_Id] ASC),
    CONSTRAINT [TrackingAttributeValues_FK_AttributeID] FOREIGN KEY ([Attribute_Id]) REFERENCES [dbo].[VendorAttributes] ([Attribute_Id]),
    CONSTRAINT [TrackingAttributeValues_FK_UDE_Id] FOREIGN KEY ([UDE_Id]) REFERENCES [dbo].[User_Defined_Events] ([UDE_Id])
);

