      program hydens

c Program to calculate the electron density at given x,y,z in the unit cell
c based on structure factor data. The main intention is to evaluate electron
c density for hydrogen positions in high resolution structures.

      implicit none

c relevant structure factor file data
      integer    MAXREF
      parameter (MAXREF=1 000 000)
      real       a(MAXREF), p(MAXREF)
      integer    hkl(3,MAXREF)
      integer    nref

c relevant pdb file data
      integer    MAXATM
      parameter (MAXATM=100 000)
      real       xyz(3, MAXATM), b(MAXATM), o(MAXATM), v
      character  atnam(MAXATM)*4, resnam(MAXATM)*6
      integer    resnum(MAXATM)
      integer    natm

c program variables
      real getrho
      real       rho(MAXATM), rms
      integer    i

C-----------------------------------------------------------------------

      natm = MAXATM
      call readpdb(atnam, resnam, resnum, xyz, b, o, v, natm)

      nref = MAXREF
      call readhkl(hkl, a, p, v, nref)

      write(*,*)' Give the standard deviation (=RMS) of the map'
      write(*,*)' Type 1 if you do not know or do not care'
      read(*,*)rms

      do i=1,natm
        rho(i) = getrho(xyz(1,i), hkl, a, p, v, nref)
        write(*,*)atnam(i), resnam(i), resnum(i), b(i), o(i), rho(i),
     $    rho(i)/rms
      enddo

      end

CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

      subroutine readpdb(atnam, resnam, resnum, xyz, b, o, v, natm)

c read relevant data from a pdb file. Request file name from user

      implicit none

c function calling/return variables
      integer    natm
      real       xyz(3, natm), b(natm), o(natm), v, scale(3,4)
      character  atnam(natm)*4, resnam(natm)*6
      integer    resnum(natm)

c local variables
      character  filnam*80, line*80
      integer    i, maxatm
      real       cell(6), celvol

C-----------------------------------------------------------------------

      write(*,*)'Give the input PDB file name (A80)'
      read(*,'(a80)')filnam
      open(unit=1,file=filnam,status='old')

      maxatm = natm
      natm   = 0
  100 continue
        read(1,'(A80)', end=101)line
        if(line(1:4).eq.'CRYS')then
          read(line(7:80),*)cell
c cell volume calculation. Works for all space groups
          v = celvol(cell)
          call scalematrix(cell, scale)
        endif
        if(line(1:4).ne.'ATOM' .and. line(1:4).ne.'HETA') goto 100
        natm = natm+1
        if(natm.gt.maxatm) goto 100
        read(line,'(12x,a4,a6,i4,4x,3f8.3,2f6.2)') atnam(natm),
     $    resnam(natm), resnum(natm), (xyz(i,natm),i=1,3), o(natm),
     $    b(natm)
c insert proper conversion of xyz to fractional coordinates here !!!!!!!!
c this version only works for orthogonal space groups.
c use the scale matrix calculated above instead
        do i=1,3
          xyz(i,natm) = xyz(i,natm)/cell(i)
        enddo
      goto 100

  101 continue
      if(natm.gt.maxatm)then
        write(*,*)'Too many atoms in input file.'
        write(*,*)'Increase paramter MAXATM to at least:',natm
        STOP 'Aborting execution. Change MAXATM and recompile.'
      endif

      if(v .gt. 0.0)then
        write(*,*)'Unit cell volume =', v
      else
        STOP 'No CRYST1 card in PDB file. Please fix this'
      endif

      write(*,*)natm,' atoms read successfully from input file'

      close (1)

      end

CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

      subroutine readhkl(hkl, a, p, v, nref)

c read reflection data from a file. Request file name from user
c file must contain h, k, l, amplitude, and phase in that order in any
c format. phases should be in degrees and a full hemisphere of data is
c needed

      implicit none

c function calling/return variables
      integer    nref
      real       xyz(3), a(nref), p(nref), v
      integer    hkl(3,nref)

c local variables
      character  filnam*80
      real       torad
      integer    i, maxref

C-----------------------------------------------------------------------

      torad = asin(1.0)/90.0

      write(*,*)'Give the input structure factor file name (A80)'
      read(*,'(a80)')filnam
      open(unit=1,file=filnam,status='old')

      maxref = nref
      nref   = 1
  100 continue
        if(nref.le.maxref)then
          read(1,*, end=101)(hkl(i,nref),i=1,3), a(nref), p(nref)
c convert to radians
          p(nref) = p(nref)*torad
          nref = nref+1
        else
          read(1,*, end=101)
          nref = nref+1
        endif
      goto 100

  101 continue
      if(nref.gt.maxref)then
        write(*,*)'Too many reflections in input file.'
        write(*,*)'Increase paramter MAXREF to at least:',nref
        STOP 'Aborting execution. Change MAXREF and recompile.'
      endif

      nref = nref-1
      write(*,*)nref,' reflections read successfully from input file'

      close (1)

      end

CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

      function getrho(xyz, hkl, a, p, v, nref)

c calculate the electron density at position xyz, given a structure factor
c set with indices in array hkl, phases in array alpha, and the unit cell
c volume in variableV

      implicit none

c function calling/return variables
      real getrho

      integer    nref
      real       xyz(3), a(nref), p(nref), v
      integer    hkl(3,nref)

c local variables
      integer    i
      real       twopi, phase, costerm, volfactor

C-----------------------------------------------------------------------

      twopi = acos(-1.0) * 2

      costerm = 0.0
      do i=1,nref
        phase = (hkl(1,i)*xyz(1)+hkl(2,i)*xyz(2)+hkl(3,i)*xyz(3))*twopi
     $   - p(i)
        costerm = costerm + a(i)*cos(phase)
      enddo

      volfactor = 2.0/v
      getrho = costerm * volfactor

      end

CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

      real function celvol(cell)
c calculate unit cell volume based on its cell parameters

      implicit none

      real cell(6), cosa, cosb, cosg, deg2rad

      deg2rad = asin(1.0)/90.0

      cosa = cos(deg2rad*cell(4))
      cosb = cos(deg2rad*cell(5))
      cosg = cos(deg2rad*cell(6))
      celvol = cell(1) * cell(2) * cell(3) *
     $  sqrt(1.0 - cosa**2 - cosb**2 - cosg**2 + 2*cosa*cosb*cosg)

      end

CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

      subroutine scalematrix(cryst1, scale)

C.....GENERATE SCALE MATRIX (SEE MCF DESCRIPTION).
C     GENERAL TRICLINIC CASE.

      real cryst1(6), scale(3,4), sclinv(3,4)

      AX=CRYST1(1)
      BX=CRYST1(2)
      CX=CRYST1(3)
      TORAD = ASIN(1.)/90.0
      SING = SIN(CRYST1(6)*TORAD)
      COSA = COS(CRYST1(4)*TORAD)
      COSB = COS(CRYST1(5)*TORAD)
      COSG = COS(CRYST1(6)*TORAD)
      V = AX*BX*CX*SQRT(1-COSA**2-COSB**2-COSG**2+2*COSA*COSB*COSG)
      SCLINV(1,1) = AX
      SCLINV(2,1) = 0
      SCLINV(3,1) = 0
      SCLINV(1,2) = BX*COSG
      SCLINV(2,2) = BX*SING
      SCLINV(3,2) = 0
      SCLINV(1,3) = CX*COSB
      SCLINV(2,3) = (CX*(COSA-(COSB*COSG)))/SING
      SCLINV(3,3) = V/(AX*BX*SING)
      SCLINV(1,4) = 0
      SCLINV(2,4) = 0
      SCLINV(3,4) = 0
C
C.....NOW INVERT THIS MATRIX
C
      CALL INVRS(SCLINV,DET,SCALE)

      SCALE(1,4)=0.
      SCALE(2,4)=0.
      SCALE(3,4)=0.

      END

CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

      SUBROUTINE INVRS(X, DETX, XINV)
C///
C      CALCULATES THE INVERS [XINV] AND THE DETERMINANT 'DETX' OF A
C      3X3 MATRIX [X];  [XINV] MAY BE THE SAME ARRAY AS [X].
C      IF DETX = 0, [XINV] WILL BE LEFT UNDEFINED.
C\\\

      DIMENSION X(9), XINV(9)
      DIMENSION XX(9),ZZ(9)

      DO 10 I = 1,9
        XX(I) = X(I)
10    CONTINUE

      ZZ(1) = XX(5)*XX(9)-XX(6)*XX(8)
      ZZ(2) = XX(3)*XX(8)-XX(2)*XX(9)
      ZZ(3) = XX(2)*XX(6)-XX(3)*XX(5)
      ZZ(4) = XX(6)*XX(7)-XX(4)*XX(9)
      ZZ(5) = XX(1)*XX(9)-XX(3)*XX(7)
      ZZ(6) = XX(3)*XX(4)-XX(1)*XX(6)
      ZZ(7) = XX(4)*XX(8)-XX(5)*XX(7)
      ZZ(8) = XX(2)*XX(7)-XX(1)*XX(8)
      ZZ(9) = XX(1)*XX(5)-XX(2)*XX(4)
      DETX = ZZ(1)*XX(1) + ZZ(2)*XX(4) + ZZ(3)*XX(7)

      IF (DETX.EQ.0.) RETURN

      DO 20 I = 1,9
        XINV(I) = ZZ(I)/DETX
20    CONTINUE

      END

CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

