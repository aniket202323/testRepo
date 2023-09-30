CREATE TABLE [dbo].[Local_PG_Spec_UDP] (
    [Spec_UDP_ID]     INT      IDENTITY (1, 1) NOT NULL,
    [Spec_Id]         INT      NOT NULL,
    [Char_Id]         INT      NOT NULL,
    [Effective_Date]  DATETIME NOT NULL,
    [Expiration_Date] DATETIME NULL,
    [Sample_Number]   INT      NOT NULL,
    [Priority]        INT      NOT NULL,
    CONSTRAINT [Spec_UDP_PK_SpecUDPID] PRIMARY KEY CLUSTERED ([Spec_UDP_ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [Spec_UDP_CC_Chk_EffExp] CHECK ([Expiration_Date] IS NULL OR [Expiration_Date]>=[Effective_Date]),
    CONSTRAINT [Spec_UDP_FK_CharId] FOREIGN KEY ([Char_Id]) REFERENCES [dbo].[Characteristics] ([Char_Id]),
    CONSTRAINT [Spec_UDP_FK_SpecId] FOREIGN KEY ([Spec_Id]) REFERENCES [dbo].[Specifications] ([Spec_Id]),
    CONSTRAINT [Spec_UDP_UC_SpecIdCharIdED] UNIQUE NONCLUSTERED ([Spec_Id] ASC, [Char_Id] ASC, [Effective_Date] ASC) WITH (FILLFACTOR = 90)
);

