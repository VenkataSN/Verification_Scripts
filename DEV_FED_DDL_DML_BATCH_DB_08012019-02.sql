----------------------------------------------------------------
--			PROCEDURES
----------------------------------------------------------------
-- Procedure 1
create or replace PROCEDURE  DEV_FED.GETBBSID (
	pOwnerID IN VARCHAR2,
	oBBSID OUT VARCHAR2
)
AS
	sOwnerID VARCHAR2(15);

BEGIN
	sOwnerID := UPPER(pOwnerID);
    oBBSID := NULL;

	IF sOwnerID IS NULL THEN
    RAISE_APPLICATION_ERROR(-20100,'Owner ID Is Not Set');
	END IF;

    IF sOwnerID IS NOT NULL THEN
    select BBSID INTO oBBSID from tblClientComm where ClientID = sOwnerID;
	END IF;

    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'BBSID is null or not readable from Database');

    WHEN OTHERS	THEN
        RAISE_APPLICATION_ERROR(-20002, SQLERRM);

END;
/

-- Procedure 2
create or replace PROCEDURE DEV_FED.GETCLIENTSTATUS
(
  CLIENT_ID IN VARCHAR2 ,
  STATUS OUT CHAR

) AS
  sClientid VARCHAR2(10) := UPPER(CLIENT_ID);
  sqlerrm		VARCHAR2 (1024);
  oStatus CHAR  := NULL;
BEGIN
 IF sClientid IS NULL THEN
        RAISE_APPLICATION_ERROR(-20100,'Client ID Is Not Set');
  END IF;

 --Check if the client is active or a test client
 SELECT status into STATUS FROM tblclientcomm WHERE clientid = sClientid ;

    /* Log all the other exceptions under exceptions block */
	EXCEPTION
		WHEN OTHERS THEN
  		sqlerrm := SQLERRM;
  		RAISE_APPLICATION_ERROR(-20002, sqlerrm);
END GETCLIENTSTATUS;
/

-- Procedure 3
create or replace PACKAGE  DEV_FED.LANG_INTEGER AS 
  /* The package is named loosely after a similar Java class, 
     java.lang.Integer; in addition, all public package functions 
     (except toRadixString() which has no Java equivalent) are named 
     after equivalent Java methods in the java.lang.Integer class. 
  */ 
 
  /* Convert a number to string in given radix. 
     Radix must be in the range [2, 16]. 
  */ 
  function toRadixString(num in number, radix in number) return varchar2; 
  pragma restrict_references (toRadixString, WNDS, WNPS, RNDS, RNPS); 
 
  /* Convert a number to binary string. */ 
  function toBinaryString(num in number) return varchar2; 
  pragma restrict_references (toBinaryString, WNDS, WNPS, RNDS, RNPS); 
 
  /* Convert a number to hexadecimal string. */ 
  function toHexString(num in number) return varchar2; 
  pragma restrict_references (toHexString, WNDS, WNPS, RNDS, RNPS); 
 
  /* Convert a number to octal string. */ 
  function toOctalString(num in number) return varchar2; 
  pragma restrict_references (toOctalString, WNDS, WNPS, RNDS, RNPS); 
 
  /* Convert a string, expressed in decimal, to number. */ 
  function parseInt(s in varchar2) return number; 
  pragma restrict_references (parseInt, WNDS, WNPS, RNDS, RNPS); 
 
  /* Convert a string, expressed in given radix, to number. 
     Radix must be in the range [2, 16]. 
  */ 
  function parseInt(s in varchar2, radix in number) return number; 
  pragma restrict_references (parseInt, WNDS, RNDS); 
END LANG_INTEGER; 
/

create or replace PACKAGE BODY DEV_FED.LANG_INTEGER as 
  /* Takes a number between 0 and 15, and converts it to a string (character) 
     The toRadixString() function calls this function. 
 
     The caller of this function is responsible for making sure no invalid 
     number is passed as the argument.  Valid numbers include non-negative 
     integer in the radix used by the calling function.  For example, 
     toOctalString() must pass nothing but 0, 1, 2, 3, 4, 5, 6, and 7 as the 
     argument 'num' of digitToString(). 
  */ 
  function digitToString(num in number) return varchar2 as 
    digitStr varchar2(1); 
  begin 
    if (num<10) then 
      digitStr := to_char(num); 
    else 
      digitStr := chr(ascii('A') + num - 10); 
    end if; 
 
    return digitStr; 
  end digitToString; 
 
  /* Takes a character (varchar2(1)) and converts it to a number. 
     The parseInt() function calls this function. 
 
     The caller of this function is responsible for maksing sure no invalid 
     string is passed as the argument.  The caller can do this by first 
     calling the isValidNumStr() function. 
  */ 
  function digitToDecimal(digitStr in varchar2) return number as 
    num number; 
  begin 
    if (digitStr >= '0') and (digitStr <= '9') then 
      num := ascii(digitStr) - ascii('0'); 
    elsif (digitStr >= 'A') and (digitStr <= 'F') then 
      num := ascii(digitStr) - ascii('A') + 10; 
    end if; 
 
    return num; 
  end digitToDecimal; 
 
  /* Checks if the given string represents a valid number in given radix. 
     Returns true if valid; ORA-6502 if invalid. 
  */ 
  function isValidNumStr(str in out varchar2,radix in number) return boolean 
as 
    validChars varchar2(16) := '0123456789ABCDEF'; 
    valid number; 
    len number; 
    i number; 
    retval boolean; 
  begin 
    if (radix<2) or (radix>16) or (radix!=trunc(radix)) then 
      i := to_number('invalid number');  /* Forces ORA-6502 when bad radix. */ 
    end if; 
str := upper(str);  /* a-f ==> A-F */ 
    /* determine valid characters for given radix */ 
    validChars := substr('0123456789ABCDEF', 1, radix); 
    valid := 1; 
    len := length(str); 
    i := 1; 
 
    while (valid !=0) loop 
      valid := instr(validChars, substr(str, i, 1)); 
      i := i + 1; 
    end loop; 
 
    if (valid=0) then 
      retval := false; 
      i := to_number('invalid number');  /* Forces ORA-6502. */ 
    else 
      retval := true; 
    end if; 
 
    return retval; 
  end isValidNumStr; 
 
  /* This function converts a number into a string in given radix. 
     Only non-negative integer should be passed as the argument num, and 
     radix must be a positive integer in [1, 16]. 
     Otherwise, 'ORA-6502: PL/SQL: numeric or value error' is raised. 
  */ 
  function toRadixString(num in number, radix in number) return varchar2 as 
    dividend number; 
    divisor number; 
    remainder number(2); 
    numStr varchar2(2000); 
  begin 
    /* NULL NUMBER -> NULL hex string */ 
    if(num is null) then 
      return null; 
    elsif (num=0) then  /* special case */ 
      return '0'; 
    end if; 
 
    /* 
	invalid number or radix; force ORA-6502: PL/SQL: numeric or value err 
	*/
    if (num<0) or (num!=trunc(num)) or 
       (radix<2) or (radix>16) or (radix!=trunc(radix)) then 
      numStr := to_char(to_number('invalid number'));  /* Forces ORA-6502. */ 
      return numStr; 
    end if; 
 
    dividend := num; 
    numStr := '';  /* start with a null string */ 
 
    /* the actual conversion loop */ 
    while(dividend != 0) loop 
      remainder := mod(dividend, radix); 
      numStr := digitToString(remainder) || numStr; 
      dividend := trunc(dividend / radix); 
    end loop; 
 
    return numStr; 
  end toRadixString; 
 
  function toBinaryString(num in number) return varchar2 as 
  begin 
    return toRadixString(num, 2); 
  end toBinaryString; 
 
  function toHexString(num in number) return varchar2 as 
  begin 
    return toRadixString(num, 16); 
  end toHexString; 
 
  function toOctalString(num in number) return varchar2 as 
  begin 
    return toRadixString(num, 8); 
  end toOctalString; 
 
  /* The parseInt() function is equivalent to TO_NUMBER() when called 
     without a radix argument.  This is consistent with what Java does. 
  */ 
  function parseInt(s in varchar2) return number as 
  begin 
    return to_number(s); 
  end parseInt; 
 
  /* Converts a string in given radix to a number */ 
  function parseInt(s in varchar2, radix in number) return number as 
    str varchar2(2000); 
    len number; 
    decimalNumber number; 
  begin 
    /* NULL hex string -> NULL NUMBER */ 
    if(s is null) then 
      return null; 
    end if; 
 
    /* Because isValidNumStr() expects a IN OUT parameter, must use an 
       intermediate variable str.  str will be converted to uppercase 
       inside isValidNumStr(). 
    */ 
    str := s; 
    if (isValidNumStr(str, radix) = false) then 
      return -1;  /* Never executes because isValidNumStr forced ORA-6502. */ 
    end if; 
 
    len := length(str); 
    decimalNumber := 0; 
 
    /* the actual conversion loop */ 
    for i in 1..len loop 
      decimalNumber := decimalNumber*radix + digitToDecimal(substr(str, i, 
1)); 
    end loop; 
 
    return decimalNumber; 
  end parseInt; 
end LANG_INTEGER; 
/

-- Procedure 4
create or replace PROCEDURE  DEV_FED.SEEKMATCHINGRDCID (
  pType IN NUMBER DEFAULT 0,
	pDestID IN VARCHAR2 DEFAULT NULL,
	pXRefID IN VARCHAR2 DEFAULT NULL,
	oRDCID OUT VARCHAR2
)
AS
	sDestID VARCHAR2(15);
--type information
-- 0 - NOT SET
-- 1 - SOURCE
-- 2 - DEST
BEGIN
	sDestID := UPPER(pDestID);
	oRDCID := NULL;

	--check the paramaters
	IF pType = 0 THEN
    RAISE_APPLICATION_ERROR(-20100,'Type Is Not Set');
	ELSIF pType < 0 OR pType > 2 THEN
		RAISE_APPLICATION_ERROR(-20100,'Type ' || pType || ' Is Unknown');
  ELSIF sDestID IS NULL THEN
    RAISE_APPLICATION_ERROR(-20100,'Dest ID Is Not Set');
  ELSIF pXRefID IS NULL THEN
    RAISE_APPLICATION_ERROR(-20100,'XRef ID Is Not Set');
	END IF;

	--get the rdc ID
	IF pType = 1 THEN
		SELECT RDCID INTO oRDCID FROM tblSourceCrossReference WHERE DestID = sDestID AND XRefID = pXRefID;
	ELSIF pType = 2 THEN
		SELECT RDCID INTO oRDCID FROM tblCrossReference WHERE DestID = sDestID AND XRefID = pXRefID;
	END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
      oRDCID := null;
END;
/

-- Procedure 5
create or replace PROCEDURE   DEV_FED.SEEKMATCHINGXREFID (
  pType IN NUMBER DEFAULT 0,
	pDestID IN VARCHAR2 DEFAULT NULL,
	pRDCID IN VARCHAR2 DEFAULT NULL,
	oXRefID OUT VARCHAR2
)
AS
	sDestID VARCHAR2(15);
	sRDCID VARCHAR2(15);
--type information
-- 0 - NOT SET
-- 1 - SOURCE
-- 2 - DEST
BEGIN
	sDestID := UPPER(pDestID);
	sRDCID := UPPER(pRDCID);
	oXRefID := NULL;

	--check the paramaters
	IF pType = 0 THEN
    RAISE_APPLICATION_ERROR(-20100,'Type Is Not Set');
	ELSIF pType < 0 OR pType > 2 THEN
		RAISE_APPLICATION_ERROR(-20100,'Type ' || pType || ' Is Unknown');
  ELSIF sDestID IS NULL THEN
    RAISE_APPLICATION_ERROR(-20100,'Dest ID Is Not Set');
  ELSIF sRDCID IS NULL THEN
    RAISE_APPLICATION_ERROR(-20100,'RDC ID Is Not Set');
	END IF;

	--get the rdc ID
	IF pType = 1 THEN
		SELECT XRefID INTO oXRefID FROM tblSourceCrossReference WHERE DestID = sDestID AND RDCID = sRDCID;
	ELSIF pType = 2 THEN
		SELECT XRefID INTO oXRefID FROM tblCrossReference WHERE DestID = sDestID AND RDCID = sRDCID;
	END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
      oXRefID := null;
END;
/

-- Procedure 6
create or replace PROCEDURE DEV_FED.ADDBILLINGINFO (
  pClientID IN VARCHAR2 DEFAULT NULL,
	pFormatID IN VARCHAR2 DEFAULT NULL,
	pEntityType IN NUMBER DEFAULT NULL,
	pOrgLastName IN VARCHAR2 DEFAULT NULL,
	pFirstName IN VARCHAR2 DEFAULT NULL,
	pMiddleName IN CHAR DEFAULT NULL,
	pIDType IN NUMBER DEFAULT NULL,
	pID IN VARCHAR2 DEFAULT NULL,
  pAddress1 IN VARCHAR2 DEFAULT NULL,
	pAddress2 IN VARCHAR2 DEFAULT NULL,
	pCity IN VARCHAR2 DEFAULT NULL,
	pState IN CHAR DEFAULT NULL,
	pZip IN CHAR DEFAULT NULL,
	oExistingSeq OUT NUMBER
)
AS
	sClientID VARCHAR2(15);
	sFormatID VARCHAR2(10);
	sOrgLastName VARCHAR2(255);
	sFirstName VARCHAR2(255);
	sMiddleName VARCHAR2(1);
	sID VARCHAR2(255);
	sAddress1 VARCHAR2(255);
	sAddress2 VARCHAR2(255);
	sCity VARCHAR2(255);
	sState VARCHAR2(2);
	sZip VARCHAR2(9);
BEGIN
	sClientID := UPPER(pClientID);
	sFormatID := UPPER(pFormatID);
	sOrgLastName := UPPER(pOrgLastName);
	sFirstName := UPPER(pFirstName);
	sMiddleName := UPPER(pMiddleName);
	sID := UPPER(pID);
	sAddress1 := UPPER(pAddress1);
	sAddress2 := UPPER(pAddress2);
	sCity := UPPER(pCity);
	sState := UPPER(pState);
	sZip := UPPER(pZip);
	oExistingSeq := NULL;

	BEGIN
	  SELECT Seq INTO oExistingSeq FROM tblBillingInfo WHERE ClientID = sClientID AND OrgLastName = sOrgLastName AND ID = sID;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
		  oExistingSeq := 0;
  END;

	IF oExistingSeq = 0 THEN
		INSERT INTO tblBillingInfo
		(ClientID,FormatID,EntityType,OrgLastName,FirstName,MiddleName,IDType,ID,Address1,Address2,City,State,Zip)
		VALUES(sClientID,sFormatID,pEntityType,sOrgLastName,sFirstName,sMiddleName,pIDType,sID,sAddress1,sAddress2,sCity,sState,sZip);

 	  COMMIT;
	END IF;
END;
/
