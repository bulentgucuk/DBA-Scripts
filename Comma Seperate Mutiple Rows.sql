BEGIN TRAN 

DECLARE @t TABLE ( fruit VARCHAR(10) ) 

INSERT  INTO @t 
        ( fruit 
        ) 
        SELECT  'apple' 
        UNION ALL 
        SELECT  'banana' 
        UNION ALL 
        SELECT  'tomato' 

SELECT  ',' + fruit 
FROM    @t 
FOR     XML PATH 

SELECT  ',' + fruit 
FROM    @t 
FOR     XML PATH('') 

SELECT  STUFF(( SELECT  ',' + fruit 
                FROM    @t 
              FOR 
                XML PATH('') 
              ), 1, 1, '') AS fruits 

ROLLBACK 

