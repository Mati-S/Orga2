# System Programming

## 1. ¿A qué nos referimos con modo real y con modo protegido en un procesador Intel? ¿Qué particularidades tiene cada modo?

- Modo Real:
    - Trabaja en 16 bits
    - Se puede direccionar hasta 1MB de memoria
    - Hay menos modos de direccionamiento
    - No hay proteccion de memoria ni niveles de privilegio

- Modo protegido:
    - Trabaja en 32 bits
    - Se puede direccionar hasta 4GB de memoria
    - Hay más modos de direccionamiento
    - Hay 4 niveles de protección
    - El set de instrucciones depende del nivel de privilegio

## 2. Comenten en su equipo, ¿Por qué debemos hacer el pasaje de modo real a modo protegido? ¿No podríamos simplemente tener un sistema operativo en modo real? ¿Qué desventajas tendría?

Porque nos permite trabajar con 32 bits, mucha más memoria, modos de direccionamiento, y protege la memoria ante errores del usuario. Podrías tener un SO en modo real pero no tendría ninguna de estas ventajas.

## 3. ¿Qué es la GDT? ¿Cómo es el formato de un descriptor de segmento, bit a bit? Expliquen para qué sirven los campos Limit, Base, G, P, DPL, S.

La GDT es una estructura de datos que define las caracteristicas de los segmentos de memoria (Base address, limit, privilegios, etc.)

<img src="https://upload.wikimedia.org/wikipedia/commons/thumb/0/0a/SegmentDescriptor.svg/580px-SegmentDescriptor.svg.png" />

- Base: Donde empieza el segmento
- Limit: Tamaño del segmento
- G: Granularidad (en 0 es byte a byte, en 1 cada 4KBytes)
- P: Segment Present (indica si el segmento está presente en memoria)
- DPL: Descriptor del nivel de privilegios (nivel 0 - nivel 3)
- S: Descriptor Type (indica si es un segmento de sistema o de código/datos)

## 4. La tabla de la sección 3.4.5.1 Code- and Data-Segment Descriptor Types del volumen 3 del manual del Intel nos permite completar el Type, los bits 11, 10, 9, 8. ¿Qué combinación de bits tendríamos que usar si queremos especificar un segmento para ejecución y lectura de código?

Type Field: 1 0 1 0 (bits 11 - 10 - 9 - 8)

## 5. Inicialmente, vamos a definir los siguientes segmentos en la GDT:
- Un segmento para código de nivel 0 ejecución/lectura
- Un segmento para código de nivel 3 ejecución/lectura
- Un segmento para datos de nivel 0 lectura/escritura
- Un segmento para datos de nivel 3 lectura/escritura

En base le pusimos a todos 0
En limit 817 * (2^20)
En G todos en 1 porque no nos alcanzan los bits para representar el límite
En D/B todos en 1 porque el segmento contiene codigo/datos de 32 bits
En L todos en 0 porque no contienen codigo de 64 bits
En AVL todos en 1 porque
En P todos en 1 porque están en memoria
En DPL depende nivel de privilegios
En S todos en 1 porque son datos/codigo
En type execute/read o read/write

## 6. En el archivo gdt.h observen las estructuras: struct gdt_descriptor_t y el struct gdt_entry_t. ¿Qué creen que contiene la variable extern gdt_entry_t gdt[]; y extern gdt_descriptor_t GDT_DESC; ?

La variable gdt[] es un arreglo de descriptores de segmentos.
La variable GDT_DESC indica cuantos descriptores de segmento tiene el GDT y la ubicación del GDT en memoria.

## 8. 

## 13.

El registro cr0 contiene flags que controlan el modo de operacion (por ejemplo, modo real o protegido). Que flag corresponde a cada bit se puede ver en el manual

El bit PE de cr0 (el primer bit de todos) indica si el sistema operativo debe operar en modo real (bit en 0) o en modo protegido (bit en 1)

##taller 2.

##1

#b ponemos D en 1 porque el gate size es de 32 bits (p.23)

el reloj gira porque ebx (que guarda la posicion del caracter) es aumentado
de a una unidad a la vez en cada impresion. cuando llega a 4 el contador, ebx
es reseteado.

##taller paginacion

## checkpoint 1

##a

dos niveles: de supervisor/kernel (0) y de usuario (1)

## b

sea virt = dir (10 bits) | table (10 bits) | offset (12 bits)

toma del registro cr3 la direccion de la page directory y se la asigna a una variable pd. al mismo tiempo limpia los ultimos 12 bits del registro.

a una variable pd_index le asigna los 10 bits mas altos de virt

a una variable pt le asignamos la direccion de la page directory. al mismo tiempo limpiamos la page directory entry correspondiente a pd_index

a una variable pt_index le asigna los 10 bits del medio de virt

a una variable page_addr le asignamos la ubicacion de la pagina ubicada en la entrada pt_index de pt

teniendo la direccion de la pagina, le sumamos el offset de virt para conseguir la direccion fisica



## c

D: 1 si un programa escribio a la pagina referenciada por la entrada

A: 1 si un programa leyo la pagina referenciada por la entrada

PCD (Page cache disabled): hace que la página no se almacene
en memoria rápida.

PWT: hace que las escrituras a la pagina se vean reflejadas en
memoria y cache a la vez. sino es solo en cache. se usa para que distintas caches puedan acceder en memoria a los cambios hechos por las otras

U/S: indica si la página puede ser accedida por el espacio de
usuarix (bit en 1) o sólo supervisor/kernel (bit en 0).

R/W: indica si la página puede leerse y escribirse (bit en 1) o
sólo leerse (bit en 0).

P: indica si la página se encuentra cargada en memoria o no.

##d

dos que usa la tarea
una para la pila de la tarea
una para el directorio
una para la tabla de paginas

## f

la TLB es una seccion de la cache L1 que guarda las traducciones de direcciones virtuales de una pagina a direcciones fisicas. comunmente se desalojan por un
criterio Least Recently Used. Se purga al modificar las estructuras de paginacion porque esto cambiaria la traduccion de direcciones, por lo que los valores
de la cache ya no serian correctos.


##11

pushad - pushea todos los registros de proposito general
call pic_finish1 - indica al controlador de interrupciones que la interrupcion fue atendida

call sched_next_task - le pide al scheduler la proxima tarea a ejecutar, el cual se lo deja en ax

str cx - obtiene de TR el selector de la tarea actual

comp ax, cx - compara la proxima tarea a ejecutar con la tarea actual
je .fin - de ser la misma, no hace falta cambiar de contexto o hacer nada mas

mov word ... -usa el selector y el offset para saltar a la proxima tarea

##13

itera sobre las tareas, preguntando si alguna esta activa. de ser el caso, devuelve su selector. si no hay ninguna activa, pasa a la tarea idle