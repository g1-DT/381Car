#include <stdio.h>
#include <jpeglib.h>
#include <stdlib.h>
#include <wiringPi.h>
#include <time.h>
#include <math.h>

//Defines the input information to the DE2 (DE2 intake)
#define GPIO1_out 2
#define GPIO2_out 3
#define GPIO3_out 4
#define GPIO4_out 17
#define GPIO5_out 27
#define GPIO6_out 22
#define GPIO7_out 10
#define GPIO8_out 9

// Ports used to read information to DE2
#define PI_ACKNO 11
#define DE2_READY 5

// Ports used to read information to PI
#define DE2_ACKNO 21
#define PI_READY 20

// Defines input information from DE2 to PI (PI intake)
#define GPIO1_in 14 
#define GPIO2_in 15
#define GPIO3_in 18
#define GPIO4_in 23
#define GPIO5_in 24
#define GPIO6_in 25
#define GPIO7_in 8
#define GPIO8_in 7

#define MAXPIXELS 200*200*3
/* we will be using this uninitialized pointer later to store raw, uncompressd image */
unsigned char *raw_image = NULL;

int color_space = JCS_RGB; 
int width = 20;
int height = 20;
int bytes_per_pixel = 3;

void setGPIO(int size, int GPIO_out[], int inOrOut);
int read_jpeg_file(char *filename, int GPIO_in[], int GPIO_out[]);
int write_jpeg_file(char *filename);
int doHandshake(int GPIO_in[]);
void resetPiOutputs(int GPIO_out[]);
void loadGPIO(int dec, int GPIO_in[]);
void negateBits(int GPIO_in[], int GPIO_out[]);
void sendData(int GPIO_out[], int data);
int recvData(int GPIO_in[]);

/**
 * read_jpeg_file Reads from a jpeg file on disk specified by filename and saves into the
 * raw_image buffer in an uncompressed format.
 *
 * \returns positive integer if successful, -1 otherwise
 * \param *filename char string specifying the file name to read from
 *
 */
int read_jpeg_file(char *filename, int GPIO_in[], int GPIO_out[]) {
  /* these are standard libjpeg structures for reading(decompression) */
  struct jpeg_decompress_struct cinfo;
  struct jpeg_error_mgr jerr;

  /* libjpeg data structure for storing one row, that is, scanline of an image */
  JSAMPROW row_pointer[1];

  FILE *infile = fopen( filename, "rb" );
  unsigned long location = 0;
  int i = 0;

  if ( !infile ) {
    printf("Error opening jpeg file %s\n!", filename );
    return -1;
  }

  /* here we set up the standard libjpeg error handler */
  cinfo.err = jpeg_std_error( &jerr );

  /* setup decompression process and source, then read JPEG header */
  jpeg_create_decompress( &cinfo );

  /* this makes the library read from infile */
  jpeg_stdio_src( &cinfo, infile );

  /* reading the image header which contains image information */
  jpeg_read_header( &cinfo, TRUE );

  /* Uncomment the following to output image information, if needed. */
  /*
  printf( "JPEG File Information: \n" );
  printf( "Image width and height: %d pixels and %d pixels.\n", cinfo.image_width, cinfo.image_height );
  printf( "Color components per pixel: %d.\n", cinfo.num_components );
  printf( "Color space: %d.\n", cinfo.jpeg_color_space );
  */

  /* Start decompression jpeg here */
  jpeg_start_decompress( &cinfo );

  /* allocate memory to hold the uncompressed image */
  raw_image = (unsigned char*)malloc( cinfo.output_width*cinfo.output_height*cinfo.num_components );

  /* now actually read the jpeg into the raw buffer */
  row_pointer[0] = (unsigned char *)malloc( cinfo.output_width*cinfo.num_components );
  int count = 0;
  /* read one scan line at a time */
  while( cinfo.output_scanline < cinfo.image_height ) {
      jpeg_read_scanlines( &cinfo, row_pointer, 1 );
      for( i=0; i<cinfo.image_width*cinfo.num_components;i++) {
        /*
        if(count == 0) {
          count++;
          raw_image[location++] = row_pointer[0][i];
        } else if (count == 1) {
          count++;
          raw_image[location++] = 0;
        } else {
          raw_image[location++] = 0;
          count = 0;
        }
        */
        
        raw_image[location++] = row_pointer[0][i];
        //loadGPIO(row_pointer[0][i], GPIO_out);
        //printf("sending: %i, color %i\n", count, row_pointer[0][i]);
        //sendData(GPIO_out, row_pointer[0][i]);
        //resetPiOutputs(GPIO_out);
        count++;
      }
  }

  //printf("Recieved data: %i\n", recvData(GPIO_in));
/*
  for(int j = 0; j < width*height*bytes_per_pixel; j++) {
    raw_image[j] = recvData(GPIO_in);
  }
  */

  /* wrap up decompression, destroy objects, free pointers and close open files */
  jpeg_finish_decompress(&cinfo);
  jpeg_destroy_decompress(&cinfo);
  free(row_pointer[0]);
  fclose(infile);

  /* yup, we succeeded! */
  return 1;
}


/**
 * write_jpeg_file Writes the raw image data stored in the raw_image buffer
 * to a jpeg image with default compression and smoothing options in the file
 * specified by *filename.
 *
 * \returns positive integer if successful, -1 otherwise
 * \param *filename char string specifying the file name to save to
 *
 */
int write_jpeg_file(char *filename) {
  struct jpeg_compress_struct cinfo;
  struct jpeg_error_mgr jerr;

  /* this is a pointer to one row of image data */
  JSAMPROW row_pointer[1];
  FILE *outfile = fopen( filename, "wb" );

  if ( !outfile ) {
      printf("Error opening output jpeg file %s\n!", filename );
      return -1;
  }
  cinfo.err = jpeg_std_error( &jerr );
  jpeg_create_compress(&cinfo);
  jpeg_stdio_dest(&cinfo, outfile);

  /* Setting the parameters of the output file here */
  cinfo.image_width = width;
  cinfo.image_height = height;
  cinfo.input_components = bytes_per_pixel;
  cinfo.in_color_space = color_space;
  /* default compression parameters, we shouldn't be worried about these */

  jpeg_set_defaults( &cinfo );
  cinfo.num_components = 3;
  //cinfo.data_precision = 4;
  cinfo.dct_method = JDCT_FLOAT;
  jpeg_set_quality(&cinfo, 15, TRUE);
  /* Now do the compression .. */
  jpeg_start_compress( &cinfo, TRUE );
  /* like reading a file, this time write one row at a time */
  while( cinfo.next_scanline < cinfo.image_height ) {
    row_pointer[0] = &raw_image[ cinfo.next_scanline * cinfo.image_width * cinfo.input_components];
    jpeg_write_scanlines( &cinfo, row_pointer, 1 );
  }
  /* similar to read file, clean up after we're done compressing */
  jpeg_finish_compress( &cinfo );
  jpeg_destroy_compress( &cinfo );
  fclose( outfile );
  /* success code is 1! */
  return 1;
}

int main(int argc, char **argv) {
  char *infilename = "cat.jpg", *outfilename = "test_out.jpg";
  
  /* setup GPIO */
  wiringPiSetupGpio();

  int outputGPIO[10] = {GPIO1_out,GPIO2_out,GPIO3_out,GPIO4_out,GPIO5_out,GPIO6_out,GPIO7_out,GPIO8_out,PI_ACKNO,PI_READY};
  int inputGPIO[10] = {GPIO1_in,GPIO2_in,GPIO3_in,GPIO4_in,GPIO5_in,GPIO6_in,GPIO7_in,GPIO8_in,DE2_ACKNO,DE2_READY};

  setGPIO(10, outputGPIO, 0);
  setGPIO(10, inputGPIO, 1);

    for(int i = 0; i < 30; i++) {
      sendData(outputGPIO, i);
    }
    for(int i = 0; i < 30; i++) {
      sendData(outputGPIO, i);
    } 
    for(int i = 0; i < 30; i++) {
      recvData(inputGPIO);
    }

    printf("Done\n");
/*
    for(int i = 0; i < 30; i++) {
      sendData(outputGPIO, i);
    }
*/

//sendData(outputGPIO, 5);

  //printf("Recieved data: %i\n", recvData(inputGPIO));
  
  /* Try opening a jpeg*/

  //if(read_jpeg_file(infilename, inputGPIO, outputGPIO) > 0) {

      //negateBits(inputGPIO, outputGPIO);
      /* then copy it to another file */
      //if(write_jpeg_file(outfilename) < 0) {
         //return -1;
      //}
  //}

  return 0;
}

void sendData(int GPIO_out[], int data) {
  loadGPIO(data, GPIO_out);
  // Make sure the DE2_READY is high so wait until it is ready
  while(digitalRead(DE2_READY) == LOW);

  // Indicate to the DE2 the PI is ready to write
  digitalWrite(PI_ACKNO, HIGH);

  // Make sure the DE2_READY is done reading
  while(digitalRead(DE2_READY) == LOW);

  // Reset the PI acknowledge signal
  digitalWrite(PI_ACKNO, LOW);
  return;
}

void setGPIO(int size, int GPIO_out[], int inOrOut) {
  //Set the ready to low initially
  digitalWrite(PI_ACKNO, LOW);
  digitalWrite(PI_READY, LOW);

  // Input select
  if(inOrOut) {
    for(int i = 0; i < size; i++) {
      pinMode(GPIO_out[i], INPUT);
    }
    printf("Done Initializing Inputs\n");
  } 
  // Output select
  else {
    for(int i = 0; i < size; i++) {
      pinMode(GPIO_out[i], OUTPUT);
    }
    printf("Done Initializing Outputs\n");
  }
  return;
}

// Handles 1 byte of handshaking, returns modified bit
int doHandshake(int GPIO_in[]) {
  // Make sure the DE2_READY is high so wait until it is ready
  while(digitalRead(DE2_READY) == LOW);

  // Indicate to the DE2 the PI is ready to write
  digitalWrite(PI_ACKNO, HIGH);

  // Make sure the DE2_READY is done reading
  while(digitalRead(DE2_READY) == LOW);

  // Reset the PI acknowledge signal
  digitalWrite(PI_ACKNO, LOW);

  digitalWrite(PI_READY, HIGH);

  while(digitalRead(DE2_ACKNO) == 0); 

  digitalWrite(PI_READY, LOW);

  int value = 0;

  for(int i = 7; i >= 0; i--) {
    if(i == 0) {
      value = (value | digitalRead(GPIO_in[i]));
    } else {
      value = (value | digitalRead(GPIO_in[i])) << 1;
    }
  }

  digitalWrite(PI_ACKNO, LOW);
  digitalWrite(PI_READY, HIGH);
  return value;
}

// Resets all outputs on pi back to low (to stop DE2 from recieving power randomly)
void resetPiOutputs(int GPIO_out[]) {
  for(int i = 0; i < 8; i++) {
    digitalWrite(GPIO_out[i], LOW);
  }
  return;
}

void loadGPIO(int dec, int GPIO_out[]) {
  if(dec > 255) {
    printf("Error: Cannot load a value higher than 255\n");
  } else {
    for(int i = 7; i >= 0; i--) {
      digitalWrite(GPIO_out[i], (dec >> i) & 1);
    }
  }
  return;
}

void negateBits(int GPIO_in[], int GPIO_out[]) {
  for(int i = 0; i <= MAXPIXELS; i++) {
    loadGPIO(raw_image[i], GPIO_out);
    raw_image[i] = doHandshake(GPIO_in);
  }
  return;
}

int recvData(int GPIO_in[]) {
  printf("Here\n");


  digitalWrite(PI_READY, HIGH);

  //delay(100);
  printf("Here1\n");
  while(digitalRead(DE2_ACKNO) == 0); 

  digitalWrite(PI_READY, LOW);

  //delay(100);
  printf("Here2\n");
  while(digitalRead(DE2_ACKNO) == 1);

  int value = 0;
  for(int i = 7; i >= 0; i--) {
    if(i == 0) {
      value = (value | digitalRead(GPIO_in[i]));
    } else {
      value = (value | digitalRead(GPIO_in[i])) << 1;
    }
  }
  printf("Getting value: %i\n", value);
  digitalWrite(PI_READY, HIGH);

  printf("Here4\n");
  while(digitalRead(DE2_ACKNO) == 0);

  //delay(100);
  digitalWrite(PI_READY, LOW);

  while(digitalRead(DE2_ACKNO) == 1);
  printf("Here5\n");
  //delay(100);

  return value;
/*
  int value = 0;

  for(int i = 7; i >= 0; i--) {
    if(i == 0) {
      value = (value | digitalRead(GPIO_in[i]));
    } else {
      value = (value | digitalRead(GPIO_in[i])) << 1;
    }
  }


  printf("Here:\n");
  while(digitalRead(DE2_ACKNO) == 1);

  return value;
*/
}