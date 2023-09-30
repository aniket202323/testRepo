CREATE TABLE [dbo].[Alarm_SPC_Disabled_Products] (
    [ASDP_Id]  INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [ATSRD_Id] INT NOT NULL,
    [Prod_Id]  INT NOT NULL,
    CONSTRAINT [AlarmSPCDisabledProducts_PK_ASDPId] PRIMARY KEY NONCLUSTERED ([ASDP_Id] ASC),
    CONSTRAINT [AlarmSPCDisabledProducts_FK_Alarm_SPC_Rules] FOREIGN KEY ([ATSRD_Id]) REFERENCES [dbo].[Alarm_Template_SPC_Rule_Data] ([ATSRD_Id]) ON DELETE CASCADE,
    CONSTRAINT [AlarmSPCDisabledProducts_FK_Products] FOREIGN KEY ([Prod_Id]) REFERENCES [dbo].[Products_Base] ([Prod_Id]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [AlarmSPCDisabledProducts_IDX_ATSRDIdProdId]
    ON [dbo].[Alarm_SPC_Disabled_Products]([ATSRD_Id] ASC, [Prod_Id] ASC);

