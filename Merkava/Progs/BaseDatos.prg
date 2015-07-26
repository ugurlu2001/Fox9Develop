DEFINE CLASS BaseDatos AS CUSTOM
   * Propiedades
   PROTECTED aTabla[1]
   PROTECTED cRuta

   */ -------------------------------------------------------------------------- */
   PROTECTED FUNCTION Init
      WITH THIS
         .cRuta = SYS(5) + ADDBS('\Merkava\Data')
         .AgregarTabla('barrios')
         .AgregarTabla('cabecob')
         .AgregarTabla('cabecomp')
         .AgregarTabla('cabemot')
         .AgregarTabla('cabemot2')
         .AgregarTabla('cabepedc')
         .AgregarTabla('cabepusd')
         .AgregarTabla('cabevent')
         .AgregarTabla('ciudades')
         .AgregarTabla('clientes')
         .AgregarTabla('cobrador')
         .AgregarTabla('depar')
         .AgregarTabla('detacomp')
         .AgregarTabla('detamot')
         .AgregarTabla('detamot2')
         .AgregarTabla('detanotc')
         .AgregarTabla('detanotp')
         .AgregarTabla('detapedc')
         .AgregarTabla('detapusd')
         .AgregarTabla('detavent')
         .AgregarTabla('familias')
         .AgregarTabla('maesprod')
         .AgregarTabla('maquinas')
         .AgregarTabla('marcas1')
         .AgregarTabla('marcas2')
         .AgregarTabla('mecancfg')
         .AgregarTabla('mecanico')
         .AgregarTabla('modelos')
         .AgregarTabla('motivocl')
         .AgregarTabla('ot')
         .AgregarTabla('plazos')
         .AgregarTabla('proceden')
         .AgregarTabla('proveedo')
         .AgregarTabla('rubros1')
         .AgregarTabla('rubros2')
         .AgregarTabla('ruta')
         .AgregarTabla('unidad')
         .AgregarTabla('vendedor')
      ENDWITH

      IF !THIS.AbrirTablas() THEN
         RETURN .F.   && Devuelve falso (.F.) si no puede abrir todas las tablas.
      ENDIF
   ENDFUNC

   */ -------------------------------------------------------------------------- */
   PROTECTED FUNCTION Destroy
      THIS.CerrarTablas()
   ENDFUNC

   */ -------------------------------------------------------------------------- */
   PROTECTED FUNCTION AgregarTabla
      LPARAMETERS tcTabla

      * inicio { validaci�n de par�metro }
      IF PARAMETERS() < 1 THEN
         MESSAGEBOX('Muy pocos argumentos.', 0+16, THIS.Name + '.AgregarTabla()')
         RETURN .F.
      ENDIF

      IF VARTYPE(tcTabla) <> 'C' THEN
         MESSAGEBOX([El par�metro 'tcTabla' deben ser de tipo texto.], 0+16, THIS.Name + '.AgregarTabla()')
         RETURN .F.
      ENDIF

      IF EMPTY(tcTabla) THEN
         MESSAGEBOX([El par�metro 'tcTabla' no debe estar vac�o.], 0+16, THIS.Name + '.AgregarTabla()')
         RETURN .F.
      ENDIF
      * fin { validaci�n de par�metro }

      LOCAL lnFilaMatriz
      lnFilaMatriz = IIF(VARTYPE(THIS.aTabla) <> 'L', ALEN(THIS.aTabla, 1) + 1, 1)

      DIMENSION THIS.aTabla[lnFilaMatriz]
      THIS.aTabla[lnFilaMatriz] = ALLTRIM(tcTabla)
   ENDFUNC

   */ -------------------------------------------------------------------------- */
   PROTECTED FUNCTION AbrirTablas
      LOCAL lnContador, llRetorno

      FOR lnContador = 1 TO ALEN(THIS.aTabla, 1)
         IF !FILE(THIS.cRuta + THIS.aTabla[lnContador] + '.dbf') THEN
            MESSAGEBOX([El archivo de datos '] + LOWER(ALLTRIM(THIS.aTabla[lnContador]) + [.dbf]) + [' no existe.], 0+16, THIS.Name + '.AbrirTablas()')
            RETURN .F.
         ENDIF

         IF !FILE(THIS.cRuta + THIS.aTabla[lnContador] + '.cdx') THEN
            MESSAGEBOX([El archivo de �ndice '] + LOWER(ALLTRIM(THIS.aTabla[lnContador]) + [.cdx]) + [' no existe.], 0+16, THIS.Name + '.AbrirTablas()')
            RETURN .F.
         ENDIF

         llRetorno = .T.

         IF !USED(THIS.aTabla[lnContador]) THEN
            TRY
               USE (THIS.cRuta + THIS.aTabla[lnContador]) IN 0 AGAIN ORDER 0 SHARED
            CATCH
               MESSAGEBOX([No se pudo acceder al archivo '] + LOWER(ALLTRIM(THIS.aTabla[lnContador]) + [.dbf]) + [', vuelva a intentarlo m�s tarde.], 0+16, THIS.Name + '.AbrirTablas()')
               llRetorno = .F.
            ENDTRY

            IF !llRetorno THEN
               RETURN .F.
            ENDIF
         ENDIF
      ENDFOR
   ENDFUNC

   */ -------------------------------------------------------------------------- */
   PROTECTED FUNCTION CerrarTablas
      LOCAL lnContador

      FOR lnContador = 1 TO ALEN(THIS.aTabla, 1)
         IF USED(THIS.aTabla[lnContador]) THEN
            SELECT (THIS.aTabla[lnContador])
            USE
         ENDIF
      ENDFOR
   ENDFUNC
ENDDEFINE